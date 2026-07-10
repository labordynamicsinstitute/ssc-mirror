
/*
  trop_estat_loocv -- Display LOOCV hyperparameter selection diagnostics.

  Reports the regularization parameters selected via leave-one-out
  cross-validation, the LOOCV objective function value, the proportion
  of valid leave-one-out fits, the grid search style, and, when
  applicable, the coordinates of the first failed observation.

  Options
  -------
  stability    Additional stability checks: flags λ* at grid boundaries,
               reports grid dimensions, and surfaces the LOOCV search
               strategy (cycling vs exhaustive).  Useful for catching
               undersized grids in small-sample settings.
*/


program define trop_estat_loocv
    version 17
    syntax [, STABility TABle2]

    // --- Verify that trop estimation results are in memory ---
    if "`e(cmd)'" != "trop" {
        di as error "last estimates not found"
        exit 301
    }
    
    // --- Header ---
    di as txt ""
    di as txt "LOOCV Diagnostics"
    di as txt "{hline 78}"
    
    // --- Selected regularization parameters ---
    di as txt "Selected hyperparameters:"
    
    capture confirm scalar e(lambda_time)
    if !_rc {
        di as txt "  lambda_time     = " as res %10.3f e(lambda_time)
    }
    else {
        di as txt "  lambda_time     = " as res "(not available)"
    }
    
    capture confirm scalar e(lambda_unit)
    if !_rc {
        di as txt "  lambda_unit     = " as res %10.3f e(lambda_unit)
    }
    else {
        di as txt "  lambda_unit     = " as res "(not available)"
    }
    
    capture confirm scalar e(lambda_nn)
    if !_rc {
        di as txt "  lambda_nn       = " as res %10.3f e(lambda_nn)
    }
    else {
        di as txt "  lambda_nn       = " as res "(not available)"
    }

    // --- Stage-1 univariate initial triple (paper Footnote 2) ---
    // Cycling LOOCV paths seed Stage-2 coordinate descent with an argmin
    // from three univariate sweeps.  A visible gap between Stage-1 and
    // the selected triple signals that Stage-2 did real work on a non-
    // convex Q(lambda) surface.  The exhaustive paths leave these
    // scalars missing and the block is then silent.
    capture confirm scalar e(stage1_lambda_time)
    local has_stage1_t = !_rc
    capture confirm scalar e(stage1_lambda_unit)
    local has_stage1_u = !_rc
    capture confirm scalar e(stage1_lambda_nn)
    local has_stage1_n = !_rc

    local stage1_visible = 0
    if `has_stage1_t' & !missing(e(stage1_lambda_time)) local stage1_visible = 1
    if `has_stage1_u' & !missing(e(stage1_lambda_unit)) local stage1_visible = 1
    if `has_stage1_n' & !missing(e(stage1_lambda_nn))   local stage1_visible = 1

    if `stage1_visible' {
        di as txt ""
        di as txt "Stage-1 univariate init (Footnote 2; cycling only):"
        if `has_stage1_t' & !missing(e(stage1_lambda_time)) {
            local _mark_t ""
            capture confirm scalar e(lambda_time)
            if !_rc & !missing(e(lambda_time)) {
                if abs(e(stage1_lambda_time) - e(lambda_time)) > 1e-12 ///
                    local _mark_t " *"
            }
            di as txt "  Stage-1 lambda_time = " as res %10.3f e(stage1_lambda_time) as res "`_mark_t'"
        }
        if `has_stage1_u' & !missing(e(stage1_lambda_unit)) {
            local _mark_u ""
            capture confirm scalar e(lambda_unit)
            if !_rc & !missing(e(lambda_unit)) {
                if abs(e(stage1_lambda_unit) - e(lambda_unit)) > 1e-12 ///
                    local _mark_u " *"
            }
            di as txt "  Stage-1 lambda_unit = " as res %10.3f e(stage1_lambda_unit) as res "`_mark_u'"
        }
        if `has_stage1_n' & !missing(e(stage1_lambda_nn)) {
            local _mark_n ""
            capture confirm scalar e(lambda_nn)
            if !_rc & !missing(e(lambda_nn)) {
                if abs(e(stage1_lambda_nn) - e(lambda_nn)) > 1e-12 ///
                    local _mark_n " *"
            }
            di as txt "  Stage-1 lambda_nn   = " as res %10.3f e(stage1_lambda_nn) as res "`_mark_n'"
        }
        di as txt "    (* = Stage-2 cycling polished away from the seed)"
    }

    di as txt ""
    
    // --- LOOCV performance summary ---
    di as txt "LOOCV performance:"
    
    // Minimized objective function value Q(lambda_hat)
    capture confirm scalar e(loocv_score)
    if !_rc {
        di as txt "  Objective Q(" as res "λ̂" as txt ")  = " as res %10.4f e(loocv_score)
    }
    else {
        di as txt "  Objective Q(" as res "λ̂" as txt ")  = " as res "(not available)"
    }
    
    // Valid fits as a fraction of total leave-one-out iterations
    capture confirm scalar e(loocv_n_valid)
    local has_valid = !_rc
    capture confirm scalar e(loocv_n_attempted)
    local has_attempted = !_rc
    
    if `has_valid' & `has_attempted' {
        local n_valid = e(loocv_n_valid)
        local n_attempted = e(loocv_n_attempted)
        
        if `n_attempted' > 0 {
            local pct_valid = 100 * `n_valid' / `n_attempted'
            di as txt "  Valid fits      = " as res %5.0f `n_valid' ///
               as txt " / " as res %5.0f `n_attempted' ///
               as txt " (" as res %5.1f `pct_valid' as txt "%)"
            
            // Warn if more than 10% of leave-one-out fits failed
            if `pct_valid' < 90 {
                di as err "  Warning: High failure rate (>" as res "10%" ///
                   as err ") may indicate data quality issues"
            }
        }
        else {
            di as txt "  Valid fits      = " as res "(no attempts recorded)"
        }
    }
    else {
        di as txt "  Valid fits      = " as res "(not available)"
    }
    
    // Grid search style (e.g., "auto", "manual")
    if "`e(grid_style)'" != "" {
        di as txt "  Grid style      = " as res "`e(grid_style)'"
    }
    else {
        di as txt "  Grid style      = " as res "(not available)"
    }
    
    // --- First failed leave-one-out observation, if any ---
    capture confirm scalar e(loocv_first_failed_t)
    local has_failed_t = !_rc
    capture confirm scalar e(loocv_first_failed_i)
    local has_failed_i = !_rc
    
    if `has_failed_t' & `has_failed_i' {
        local first_t = e(loocv_first_failed_t)
        local first_i = e(loocv_first_failed_i)
        
        // Non-negative indices indicate at least one leave-one-out fit failed
        if `first_t' >= 0 & `first_i' >= 0 {
            di as txt ""
            di as txt "First failed observation:"
            di as txt "  Time index      = " as res %5.0f `first_t'
            di as txt "  Unit index      = " as res %5.0f `first_i'
        }
    }

    // --- Stability diagnostics (opt-in) ---
    if "`stability'" != "" {
        di as txt ""
        di as txt "Stability diagnostics:"

        // Grid dimensions.  Missing matrices are silently skipped.
        capture confirm matrix e(lambda_time_grid)
        local has_time_grid = !_rc
        capture confirm matrix e(lambda_unit_grid)
        local has_unit_grid = !_rc
        capture confirm matrix e(lambda_nn_grid)
        local has_nn_grid = !_rc
        local n_cartesian = .
        local n_t = .
        local n_u = .
        local n_n = .

        // LOOCV strategy (cycling vs exhaustive, per method)
        local method = e(method)
        if "`method'" == "joint" & "`e(joint_loocv)'" != "" {
            di as txt "  LOOCV strategy  = " as res "`e(joint_loocv)'" ///
                as txt " (joint; shared-tau extension)"
        }
        else if "`method'" == "twostep" & "`e(twostep_loocv)'" != "" {
            di as txt "  LOOCV strategy  = " as res "`e(twostep_loocv)'" ///
                as txt " (twostep; Algorithm 2 default)"
        }

        if `has_time_grid' {
            tempname gt
            matrix `gt' = e(lambda_time_grid)
            local n_t = rowsof(`gt')
            if `n_t' == 1 {
                local n_t = colsof(`gt')
            }
        }
        if `has_unit_grid' {
            tempname gu
            matrix `gu' = e(lambda_unit_grid)
            local n_u = rowsof(`gu')
            if `n_u' == 1 {
                local n_u = colsof(`gu')
            }
        }
        if `has_nn_grid' {
            tempname gn
            matrix `gn' = e(lambda_nn_grid)
            local n_n = rowsof(`gn')
            if `n_n' == 1 {
                local n_n = colsof(`gn')
            }
        }
        if `has_time_grid' & `has_unit_grid' & `has_nn_grid' {
            local n_cartesian = `n_t' * `n_u' * `n_n'
            di as txt "  Cartesian size   = " as res %6.0f `n_cartesian' ///
                as txt " grid points"
        }

        // Boundary-hit checks: if λ* coincides with the smallest or
        // largest grid point, the user-supplied grid is probably too
        // narrow and LOOCV may be selecting a corner solution.  Users
        // should then expand the grid (grid_style(fine|extended) or
        // explicit lambda_*_grid()).
        local boundary_hits = 0

        if `has_time_grid' & !missing(e(lambda_time)) {
            tempname gt
            matrix `gt' = e(lambda_time_grid)
            local n_t = rowsof(`gt')
            if `n_t' == 1 {
                local n_t = colsof(`gt')
            }
            _trop_check_grid_boundary `gt' `=e(lambda_time)' "lambda_time" "`n_t'"
            local boundary_hits = `boundary_hits' + r(boundary_hit)
            di as txt "  lambda_time grid: " as res %3.0f r(n_grid) ///
                as txt " points in [" as res %6.3f r(lo) as txt ", " ///
                as res %6.3f r(hi) as txt "]" ///
                as res "`r(hit_msg)'"
        }

        if `has_unit_grid' & !missing(e(lambda_unit)) {
            tempname gu
            matrix `gu' = e(lambda_unit_grid)
            local n_u = rowsof(`gu')
            if `n_u' == 1 {
                local n_u = colsof(`gu')
            }
            _trop_check_grid_boundary `gu' `=e(lambda_unit)' "lambda_unit" "`n_u'"
            local boundary_hits = `boundary_hits' + r(boundary_hit)
            di as txt "  lambda_unit grid: " as res %3.0f r(n_grid) ///
                as txt " points in [" as res %6.3f r(lo) as txt ", " ///
                as res %6.3f r(hi) as txt "]" ///
                as res "`r(hit_msg)'"
        }

        if `has_nn_grid' & !missing(e(lambda_nn)) {
            tempname gn
            matrix `gn' = e(lambda_nn_grid)
            local n_n = rowsof(`gn')
            if `n_n' == 1 {
                local n_n = colsof(`gn')
            }
            _trop_check_grid_boundary `gn' `=e(lambda_nn)' "lambda_nn" "`n_n'"
            local boundary_hits = `boundary_hits' + r(boundary_hit)
            di as txt "  lambda_nn   grid: " as res %3.0f r(n_grid) ///
                as txt " points in [" as res %6.3f r(lo) as txt ", " ///
                as res %6.3f r(hi) as txt "]" ///
                as res "`r(hit_msg)'"
        }

        if `boundary_hits' > 0 {
            di as err "  WARNING: `boundary_hits' boundary hit(s) detected."
            di as err "           Consider grid_style(fine) or grid_style(extended),"
            di as err "           or widen the affected lambda_*_grid() option."
        }
        else if `has_time_grid' | `has_unit_grid' | `has_nn_grid' {
            di as txt "  No grid-boundary hits (selected λ sits strictly inside each grid)."
        }

        if `n_cartesian' < . & `n_cartesian' <= 125 {
            if "`method'" == "twostep" & "`e(twostep_loocv)'" == "cycling" {
                di as txt "  Recommendation   = " as res "twostep_loocv(exhaustive)" ///
                    as txt " is practical on this grid and guarantees the grid argmin."
            }
            else if "`method'" == "joint" & "`e(joint_loocv)'" == "cycling" {
                di as txt "  Recommendation   = " as res "joint_loocv(exhaustive)" ///
                    as txt " is practical on this grid and guarantees the grid argmin."
            }
        }
    }

    // --- Table 2 coverage report (opt-in) ---
    if "`table2'" != "" {
        capture confirm matrix e(lambda_time_grid)
        local has_time_grid = !_rc
        capture confirm matrix e(lambda_unit_grid)
        local has_unit_grid = !_rc
        capture confirm matrix e(lambda_nn_grid)
        local has_nn_grid = !_rc

        if !`has_time_grid' | !`has_unit_grid' | !`has_nn_grid' {
            di as err ""
            di as err "  Table 2 coverage: lambda grids are not available in e()."
            di as err "  Run trop with LOOCV (do not pass fixedlambda()) to populate"
            di as err "  e(lambda_time_grid)/e(lambda_unit_grid)/e(lambda_nn_grid)."
        }
        else {
            capture findfile trop_lambda_grid.mata
            if _rc == 0 {
                capture mata: mata which trop_report_table2_coverage()
                if _rc {
                    // Mata function not loaded yet — pull in the lambda grid
                    // module.  _trop_load_mata is the canonical loader.
                    capture _trop_load_mata
                }
            }

            tempname _gt _gu _gn
            matrix `_gt' = e(lambda_time_grid)
            matrix `_gu' = e(lambda_unit_grid)
            matrix `_gn' = e(lambda_nn_grid)

            mata: (void) trop_report_table2_coverage( ///
                colvec_from_matrix("`_gt'"), ///
                colvec_from_matrix("`_gu'"), ///
                colvec_from_matrix("`_gn'"))
        }
    }

    di as txt "{hline 78}"
end

/* ---------------------------------------------------------------------------
  Mata helper: convert a Stata matrix (row- or column-vector shaped) into a
  real colvector suitable for `trop_report_table2_coverage`.  Declared local
  to this ado so it does not leak into the global Mata namespace under
  another name; the standalone grid-module Mata file should not be touched
  for a display-layer utility.
---------------------------------------------------------------------------- */
mata:
real colvector colvec_from_matrix(string scalar matname)
{
    real matrix M
    M = st_matrix(matname)
    if (rows(M) == 1) return(M')
    if (cols(M) == 1) return(M)
    return(vec(M))
}
end

/* ---------------------------------------------------------------------------
  _trop_check_grid_boundary helper
  ---------------------------------------------------------------------------
  Given a grid stored as a Stata matrix (column- or row-vector), the
  selected λ̂, and a display label, returns via r() the grid size, the
  min/max, a human-readable hit message, and a 0/1 flag marking whether
  λ̂ coincides with the grid's lower or upper endpoint (bit-equality, not
  ε-comparison: LOOCV always selects a grid point so exact match is the
  right test).  The infinity sentinel ("." → +Inf) is handled specially:
  an infinite upper bound or λ̂ is reported without a boundary flag
  because `infinity` is a legitimate corner (DID/TWFE special case) rather
  than an undersized grid.
---------------------------------------------------------------------------- */
program define _trop_check_grid_boundary, rclass
    args grid lambda_hat label n_grid

    // Extract min / max of the grid as scalar strings.  The grid matrix
    // may be row- or column-vector shaped; `vec()` flattens both cases
    // and `[1,1]` turns the reduction's 1×1 matrix into a scalar so
    // st_local gets a plain string.  Missing (Stata's +∞ sentinel) is
    // propagated by colmax so the helper can recognise it and skip the
    // upper-boundary hit test in the DID/TWFE λ_nn = ∞ case.
    mata: st_local("_tmp_lo", strofreal(colmin(vec(st_matrix("`grid'")))[1,1]))
    mata: st_local("_tmp_hi", strofreal(colmax(vec(st_matrix("`grid'")))[1,1]))

    local hit_lo = (`lambda_hat' == `_tmp_lo' & `n_grid' > 1)
    local hit_hi = 0
    // "." sentinel for +Inf must not count as an undersized grid.  If the
    // grid contains missing (∞), the upper bound is effectively unbounded
    // and λ_hat = max_finite_grid_point still isn't a "boundary hit" in
    // the same sense.  Stata reports missing as +Inf in max().
    if "`_tmp_hi'" != "." {
        local hit_hi = (`lambda_hat' == `_tmp_hi' & `n_grid' > 1)
    }

    local hit = (`hit_lo' + `hit_hi')
    local msg ""
    if `hit_lo' {
        local msg " ← λ̂ at LOWER boundary"
    }
    else if `hit_hi' {
        local msg " ← λ̂ at UPPER boundary"
    }

    return local hit_msg "`msg'"
    return scalar boundary_hit = `hit'
    return scalar n_grid = `n_grid'
    return scalar lo = `_tmp_lo'
    return scalar hi = `_tmp_hi'
end
