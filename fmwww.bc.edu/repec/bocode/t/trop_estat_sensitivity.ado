/*
    Post-estimation command for hyperparameter sensitivity analysis.

    Visualizes and summarizes the LOOCV (Leave-One-Out Cross-Validation)
    grid search results, including the hyperparameter search space, optimal
    selection, and boundary diagnostics.

    Syntax:
        estat sensitivity [, graph table(#)]

    Options:
        graph    - Plot the CV loss curve (requires full grid evaluation).
        table(#) - Number of top grid points to display (default: 10).
*/


program define trop_estat_sensitivity
    version 17
    syntax [, graph table(integer 10)]

    // Verify previous trop estimation results
    if "`e(cmd)'" != "trop" {
        di as error "last estimates not found"
        exit 301
    }

    // Check for lambda grids
    capture confirm matrix e(lambda_time_grid)
    local has_grids = (_rc == 0)

    capture confirm matrix e(lambda_grid)
    local has_lambda_grid = (_rc == 0)

    capture confirm matrix e(cv_curve)
    local has_cv_curve = (_rc == 0)

    if !`has_grids' & !`has_lambda_grid' {
        di as error "No LOOCV search results available."
        di as error "Run {bf:trop} with LOOCV enabled (default)."
        exit 111
    }

    // Check for full grid evaluation data
    local full_cv = 0
    if `has_cv_curve' {
        mata: _check_cv_completeness()
        local full_cv = r(cv_complete)
    }

    // Display results based on available data
    if `full_cv' {
        _display_full_sensitivity `table'
    }
    else {
        _display_grid_sensitivity
    }

    // Generate graph if requested
    if "`graph'" != "" {
        if `full_cv' {
            _graph_cv_curve
        }
        else {
            di as txt ""
            di as txt "Note: CV curve graph requires full grid evaluation data."
            di as txt "      The cycling (coordinate descent) LOOCV search does not"
            di as txt "      evaluate all grid combinations."
        }
    }
end

/*
    Displays summary statistics for the coordinate descent LOOCV search.
    Reports the search range for each regularization parameter (lambda_time,
    lambda_unit, lambda_nn), the selected optimum, the corresponding LOOCV
    score, and checks for boundary solutions.
*/

program define _display_grid_sensitivity
    di as txt ""
    di as txt "{hline 78}"
    di as txt "Hyperparameter Sensitivity Analysis"
    di as txt "{hline 78}"

    local opt_time = e(lambda_time)
    local opt_unit = e(lambda_unit)
    local opt_nn = e(lambda_nn)
    local opt_score = e(loocv_score)
    local method = "`e(method)'"
    local loocv_mode ""

    if "`method'" == "joint" {
        local loocv_mode "`e(joint_loocv)'"
        if "`loocv_mode'" == "" local loocv_mode "exhaustive"
        di as txt "Method: " as res "joint" ///
            as txt " (Remark 6.1 extension; shared tau)"
    }
    else {
        local loocv_mode "`e(twostep_loocv)'"
        if "`loocv_mode'" == "" local loocv_mode "cycling"
        di as txt "Method: " as res "twostep" ///
            as txt " (Algorithm 2 default; heterogeneous tau_it)"
    }
    if "`loocv_mode'" == "exhaustive" {
        di as txt "LOOCV search: " as res "exhaustive" ///
            as txt " (Cartesian product; guaranteed grid argmin)"
    }
    else {
        di as txt "LOOCV search: " as res "cycling" ///
            as txt " (coordinate descent)"
    }
    di as txt ""

    // Display grid summary table
    di as txt "Grid search space:"
    di as txt "{hline 78}"
    di as txt "  Parameter       Grid points    Min        Max        Optimal"
    di as txt "{hline 78}"

    mata: _display_grid_row("time")
    mata: _display_grid_row("unit")
    mata: _display_grid_row("nn")

    di as txt "{hline 78}"

    // Optimal LOOCV score
    di as txt ""
    di as txt "Optimal LOOCV score: " as res %12.6f `opt_score'

    // Boundary diagnostics
    di as txt ""
    di as txt "Boundary diagnostics:"
    mata: _boundary_check()

    local n_edge = r(n_edge)
    if `n_edge' == 0 {
        di as txt "  " as res "No boundary issues detected." as txt " Optimal is interior to all grids."
    }

    di as txt "{hline 78}"

    // Total grid size
    capture confirm matrix e(lambda_grid)
    if _rc == 0 {
        di as txt ""
        di as txt "Grid space (Cartesian product): " as res `= rowsof(e(lambda_grid))' as txt " combinations"
        if "`loocv_mode'" == "cycling" {
            di as txt "Note: Coordinate descent (cycling) evaluates O(|grid| x cycles) points,"
            di as txt "      not the full Cartesian product."
        }
        else {
            di as txt "Note: Exhaustive LOOCV evaluates the full Cartesian product."
        }
    }
end

/*
    Displays full grid search results.
    Ranks grid points by CV loss, reporting the top candidates and sensitivity
    metrics (coefficient of variation, loss range, relative range).
*/

program define _display_full_sensitivity
    args n_display

    tempname lambda_grid cv_curve
    matrix `lambda_grid' = e(lambda_grid)
    matrix `cv_curve' = e(cv_curve)

    local n_grid = rowsof(`lambda_grid')
    local n_display = min(`n_display', `n_grid')

    di as txt ""
    di as txt "{hline 78}"
    di as txt "Hyperparameter Sensitivity Analysis (Full Grid)"
    di as txt "{hline 78}"

    // Find the row corresponding to the optimal hyperparameters
    mata: _find_optimal_row()
    local opt_row = r(opt_row)

    // Select top grid points by ascending CV loss
    mata: _select_rows_around_optimal(`opt_row', `n_display', `n_grid')
    local n_display = r(n_display_actual)

    di as txt "Grid search results (showing `n_display' points with lowest CV loss):"
    di as txt ""
    di as txt "  lambda_time  lambda_unit  lambda_nn   CV_loss"
    di as txt "{hline 78}"

    forvalues i = 1/`n_display' {
        local row_idx = r(display_row_`i')

        local lam_time = `lambda_grid'[`row_idx', 1]
        local lam_unit = `lambda_grid'[`row_idx', 2]
        local lam_nn = `lambda_grid'[`row_idx', 3]
        local cv_loss = `cv_curve'[`row_idx', 4]

        local marker = ""
        if `row_idx' == `opt_row' {
            local marker = "*"
        }

        di as txt "  " as res %11.3f `lam_time' ///
            "  " %11.3f `lam_unit' ///
            "  " %9.3f `lam_nn' ///
            "  " %9.3f `cv_loss' ///
            as txt "    `marker'"
    }

    di as txt "{hline 78}"
    di as txt "* Optimal hyperparameters"

    // Compute sensitivity metrics
    mata: _compute_sensitivity_metrics()

    di as txt ""
    di as txt "Sensitivity metrics:"
    di as txt "  Coefficient of Variation: " as res %6.3f r(cv_coef) ///
        as txt "   `r(cv_label)'"
    di as txt "  CV loss range:            [" as res %6.3f r(cv_min) ///
        as txt ", " as res %6.3f r(cv_max) as txt "]"
    di as txt "  Relative range:           " as res %6.1f r(cv_rel_range) "%"
    di as txt "{hline 78}"
end

/*
    Generates the CV loss curve plot.
    Selects the appropriate plotting routine based on the number of varying
    regularization parameters.
*/

program define _graph_cv_curve
    mata: _detect_lambda_dimensions()
    local n_vary = r(n_vary)

    if `n_vary' == 1 {
        _graph_cv_1d
    }
    else if `n_vary' == 2 {
        di as txt ""
        di as txt "Note: 2D contour plot requires grid-formatted data."
        di as txt "      Use {bf:table(#)} option to inspect specific slices."
    }
    else {
        di as txt ""
        di as txt "Note: CV surface has `n_vary' varying dimensions."
        di as txt "      Use {bf:table(#)} option to inspect results."
    }
end

/*
    Plots CV loss against a single varying regularization parameter.
    Includes a reference line at the optimal value.
*/

program define _graph_cv_1d
    local varying_lambda = "`r(varying_lambda_1)'"

    tempname lambda_grid cv_curve
    matrix `lambda_grid' = e(lambda_grid)
    matrix `cv_curve' = e(cv_curve)

    if "`varying_lambda'" == "time" {
        local col = 1
        local xlab = "λ{subscript:time}"
    }
    else if "`varying_lambda'" == "unit" {
        local col = 2
        local xlab = "λ{subscript:unit}"
    }
    else {
        local col = 3
        local xlab = "λ{subscript:nn}"
    }

    preserve
    clear
    local n_points = rowsof(`cv_curve')
    quietly {
        set obs `n_points'
        gen double lambda_val = .
        gen double cv_loss = .
    }

    forvalues i = 1/`n_points' {
        qui replace lambda_val = `lambda_grid'[`i', `col'] in `i'
        qui replace cv_loss = `cv_curve'[`i', 4] in `i'
    }

    qui drop if missing(cv_loss)

    if _N == 0 {
        di as txt "Note: No CV loss data available for plotting."
        restore
        exit
    }

    if "`varying_lambda'" == "time" {
        local opt_val = e(lambda_time)
    }
    else if "`varying_lambda'" == "unit" {
        local opt_val = e(lambda_unit)
    }
    else {
        local opt_val = e(lambda_nn)
    }

    twoway line cv_loss lambda_val, ///
        sort ///
        xline(`opt_val', lcolor(red) lpattern(dash)) ///
        title("CV Loss vs `xlab'") ///
        xtitle("`xlab'") ///
        ytitle("LOOCV Loss") ///
        note("Optimal: `xlab' = `opt_val'") ///
        scheme(s2color)

    restore
end

// --------------------------------------------------------------------------
//  Mata Utilities
// --------------------------------------------------------------------------

version 17
mata:
mata set matastrict on

/*
    Checks if the stored CV curve matrix contains sufficient data for full-grid analysis.
    Returns r(cv_complete) = 1 if more than half of the rows have valid CV scores,
    0 otherwise.
*/
void _check_cv_completeness()
{
    real matrix cv_curve
    real scalar n_rows, n_nonmissing, i

    cv_curve = st_matrix("e(cv_curve)")
    n_rows = rows(cv_curve)

    if (n_rows == 0) {
        st_numscalar("r(cv_complete)", 0)
        return
    }

    n_nonmissing = 0
    for (i = 1; i <= n_rows; i++) {
        if (cv_curve[i, 4] < .) {
            n_nonmissing++
        }
    }

    st_numscalar("r(cv_complete)", (n_nonmissing > n_rows / 2) ? 1 : 0)
}

/*
    Prints a summary row for a specific regularization parameter.
    Displays the number of grid points, minimum, maximum, and selected optimal value.
*/
void _display_grid_row(string scalar param)
{
    real matrix grid
    real scalar opt_val, n_pts, grid_min, grid_max
    string scalar matname, label

    if (param == "time") {
        matname = "e(lambda_time_grid)"
        label = "lambda_time"
        opt_val = st_numscalar("e(lambda_time)")
    }
    else if (param == "unit") {
        matname = "e(lambda_unit_grid)"
        label = "lambda_unit"
        opt_val = st_numscalar("e(lambda_unit)")
    }
    else {
        matname = "e(lambda_nn_grid)"
        label = "lambda_nn  "
        opt_val = st_numscalar("e(lambda_nn)")
    }

    grid = st_matrix(matname)
    if (rows(grid) == 0) return

    n_pts = cols(grid)
    grid_min = min(grid)
    grid_max = max(grid)

    printf("  %s   %5.0f      %9.3f  %9.3f  %9.3f\n",
           label, n_pts, grid_min, grid_max, opt_val)
}

/*
    Checks if the optimal hyperparameters lie on the boundary of the grid search space.
    Issues a warning if a boundary solution is found.
    Returns r(n_edge) as the count of parameters at the boundary.
*/
void _boundary_check()
{
    real matrix grid
    real scalar opt_val
    real scalar n_edge, p
    real scalar grid_min, grid_max
    string scalar param

    n_edge = 0

    for (p = 1; p <= 3; p++) {
        if (p == 1) {
            grid = st_matrix("e(lambda_time_grid)")
            opt_val = st_numscalar("e(lambda_time)")
            param = "lambda_time"
        }
        else if (p == 2) {
            grid = st_matrix("e(lambda_unit_grid)")
            opt_val = st_numscalar("e(lambda_unit)")
            param = "lambda_unit"
        }
        else {
            grid = st_matrix("e(lambda_nn_grid)")
            opt_val = st_numscalar("e(lambda_nn)")
            param = "lambda_nn"
        }

        if (rows(grid) == 0 || cols(grid) <= 1) continue

        grid_min = min(grid)
        grid_max = max(grid)

        if (abs(opt_val - grid_min) < 1e-10) {
            printf("  {err}Warning:{txt} %s optimal (%9.3f) is at the {bf:lower} grid boundary.\n",
                   param, opt_val)
            printf("  {txt}         Consider extending the grid below %9.3f.\n", grid_min)
            n_edge++
        }
        else if (abs(opt_val - grid_max) < 1e-10) {
            printf("  {err}Warning:{txt} %s optimal (%9.3f) is at the {bf:upper} grid boundary.\n",
                   param, opt_val)
            printf("  {txt}         Consider extending the grid above %9.3f.\n", grid_max)
            n_edge++
        }
    }

    st_numscalar("r(n_edge)", n_edge)
}

/*
    Finds the index of the grid point closest to the optimal hyperparameters.
    Returns the 1-based row index in r(opt_row).
*/
void _find_optimal_row()
{
    real matrix lambda_grid
    real scalar lambda_time_opt, lambda_unit_opt, lambda_nn_opt
    real scalar i, n_rows, opt_row
    real scalar dist, min_dist

    lambda_grid = st_matrix("e(lambda_grid)")
    lambda_time_opt = st_numscalar("e(lambda_time)")
    lambda_unit_opt = st_numscalar("e(lambda_unit)")
    lambda_nn_opt = st_numscalar("e(lambda_nn)")

    n_rows = rows(lambda_grid)
    min_dist = 1e100
    opt_row = 1

    for (i = 1; i <= n_rows; i++) {
        dist = sqrt((lambda_grid[i,1] - lambda_time_opt)^2 +
                    (lambda_grid[i,2] - lambda_unit_opt)^2 +
                    (lambda_grid[i,3] - lambda_nn_opt)^2)
        if (dist < min_dist) {
            min_dist = dist
            opt_row = i
        }
    }

    st_numscalar("r(opt_row)", opt_row)
}

/*
    Selects the top performing grid points based on CV loss.
    Returns indices of the rows with the lowest CV loss values.
*/
void _select_rows_around_optimal(real scalar opt_row, real scalar n_display, real scalar n_grid)
{
    real matrix cv_curve
    real colvector cv_loss, valid_idx
    real scalar i, n_valid
    real scalar count

    cv_curve = st_matrix("e(cv_curve)")
    cv_loss = cv_curve[., 4]

    // Identify indices with valid CV loss
    valid_idx = J(n_grid, 1, 0)
    n_valid = 0
    for (i = 1; i <= n_grid; i++) {
        if (cv_loss[i] < .) {
            n_valid++
            valid_idx[n_valid] = i
        }
    }

    if (n_valid == 0) {
        st_numscalar("r(display_row_1)", opt_row)
        return
    }

    // Sort valid indices by ascending CV loss
    valid_idx = valid_idx[1::n_valid]
    real colvector valid_loss, sort_order
    valid_loss = cv_loss[valid_idx]
    sort_order = order(valid_loss, 1)
    valid_idx = valid_idx[sort_order]

    count = min((n_display, n_valid))
    for (i = 1; i <= count; i++) {
        st_numscalar("r(display_row_" + strofreal(i) + ")", valid_idx[i])
    }
    st_numscalar("r(n_display_actual)", count)
}

/*
    Computes sensitivity metrics for the CV loss distribution.
    Metrics include the coefficient of variation, range, and relative range.
    Returns results in r().
*/
void _compute_sensitivity_metrics()
{
    real matrix cv_curve
    real colvector cv_loss, valid_loss
    real scalar n_rows, n_valid, i
    real scalar cv_mean, cv_sd, cv_coef
    real scalar cv_min, cv_max, cv_range, cv_rel_range
    string scalar cv_label

    cv_curve = st_matrix("e(cv_curve)")
    cv_loss = cv_curve[., 4]
    n_rows = rows(cv_loss)

    // Filter valid CV loss values
    valid_loss = J(n_rows, 1, .)
    n_valid = 0
    for (i = 1; i <= n_rows; i++) {
        if (cv_loss[i] < .) {
            n_valid++
            valid_loss[n_valid] = cv_loss[i]
        }
    }

    if (n_valid <= 1) {
        st_numscalar("r(cv_coef)", 0)
        st_numscalar("r(cv_min)", (n_valid > 0) ? valid_loss[1] : .)
        st_numscalar("r(cv_max)", (n_valid > 0) ? valid_loss[1] : .)
        st_numscalar("r(cv_rel_range)", 0)
        st_global("r(cv_label)", "(insufficient data)")
        return
    }

    valid_loss = valid_loss[1::n_valid]

    cv_mean = mean(valid_loss)
    cv_sd = sqrt(variance(valid_loss))
    cv_coef = (abs(cv_mean) > 1e-15) ? cv_sd / cv_mean : .

    cv_min = min(valid_loss)
    cv_max = max(valid_loss)
    cv_range = cv_max - cv_min
    cv_rel_range = (cv_min > 1e-15) ? cv_range / cv_min * 100 : 0

    if (cv_coef >= .) {
        cv_label = "(undefined: mean CV loss is zero)"
    }
    else if (cv_coef < 0.1) {
        cv_label = "(low sensitivity)"
    }
    else if (cv_coef < 0.3) {
        cv_label = "(moderate sensitivity)"
    }
    else {
        cv_label = "(high sensitivity)"
    }

    st_numscalar("r(cv_coef)", cv_coef)
    st_numscalar("r(cv_min)", cv_min)
    st_numscalar("r(cv_max)", cv_max)
    st_numscalar("r(cv_rel_range)", cv_rel_range)
    st_global("r(cv_label)", cv_label)
}

/*
    Identifies which regularization parameters vary across the grid.
    Returns r(n_vary) and the names of the varying parameters.
*/
void _detect_lambda_dimensions()
{
    real matrix lambda_grid
    real scalar n_vary
    real scalar var_time, var_unit, var_nn

    lambda_grid = st_matrix("e(lambda_grid)")
    n_vary = 0

    var_time = variance(lambda_grid[., 1])
    if (var_time > 1e-10) {
        n_vary++
        st_global("r(varying_lambda_1)", "time")
    }

    var_unit = variance(lambda_grid[., 2])
    if (var_unit > 1e-10) {
        n_vary++
        if (n_vary == 1) st_global("r(varying_lambda_1)", "unit")
        else if (n_vary == 2) st_global("r(varying_lambda_2)", "unit")
    }

    var_nn = variance(lambda_grid[., 3])
    if (var_nn > 1e-10) {
        n_vary++
        if (n_vary == 1) st_global("r(varying_lambda_1)", "nn")
        else if (n_vary == 2) st_global("r(varying_lambda_2)", "nn")
        else if (n_vary == 3) st_global("r(varying_lambda_3)", "nn")
    }

    st_numscalar("r(n_vary)", n_vary)
}

end
