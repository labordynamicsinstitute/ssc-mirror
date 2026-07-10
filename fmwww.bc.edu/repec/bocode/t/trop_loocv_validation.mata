/*──────────────────────────────────────────────────────────────────────────────
  trop_loocv_validation.mata

  Validation of LOOCV-selected regularization parameters against
  empirical reference values from seven benchmark applications.

  The reference triplets (lambda_time, lambda_unit, lambda_nn) correspond
  to the LOOCV-optimal tuning parameters reported for the semi-synthetic
  simulation designs and empirical case studies.  These serve as
  regression-test anchors: if the implementation's LOOCV selects
  materially different values on the same data, a discrepancy is flagged.

  Contents
    validate_lambda_vs_table2()   compare estimated vs reference lambdas
    get_table2_lambda()           retrieve reference lambda triplet
    get_table2_rmse()             retrieve reference LOOCV RMSE
──────────────────────────────────────────────────────────────────────────────*/

version 17
mata:

/*──────────────────────────────────────────────────────────────────────────────
  validate_lambda_vs_table2()

  Checks whether LOOCV-selected regularization parameters match reference
  values within specified tolerances.

  Tolerance (dual-criterion, per component j):
    - If reference lambda_j < 0.01:  |error| <= 0.05
    - Otherwise:  |relative error| <= 10%  AND  |error| <= 0.05

  Arguments
    lambda_impl   3 x 1 vector [lambda_time; lambda_unit; lambda_nn]
    baseline_id   scalar in {1,...,7} identifying the reference application
    verbose       optional; if nonzero, prints diagnostics (default: 1)

  Reference lambda values [lambda_time, lambda_unit, lambda_nn]
    1. CPS logwage   (0.10, 0.00, 0.900)
    2. CPS urate     (0.35, 1.60, 0.011)
    3. PWT           (0.40, 0.30, 0.006)
    4. Germany       (0.20, 1.20, 0.011)
    5. Basque        (0.35, 0.00, 0.006)
    6. Smoking       (0.40, 0.25, 0.011)
    7. Boatlift      (0.20, 0.20, 0.151)

  Returns
    "PASS" if all three components satisfy the tolerance criteria,
    "FAIL: ..." with a description of the first failing component otherwise
──────────────────────────────────────────────────────────────────────────────*/

string scalar function validate_lambda_vs_table2(
    real colvector lambda_impl,
    real scalar baseline_id,
    | real scalar verbose
)
{
    if (args() < 3) verbose = 1

    real matrix table2_lambdas
    real colvector lambda_ref
    string rowvector param_names
    string scalar failure_msg
    real scalar j, lambda_p, lambda_i, rel_err, abs_err
    real scalar pass_count

    table2_lambdas = (
        0.1,  0.0,  0.9   \
        0.35, 1.6,  0.011 \
        0.4,  0.3,  0.006 \
        0.2,  1.2,  0.011 \
        0.35, 0.0,  0.006 \
        0.4,  0.25, 0.011 \
        0.2,  0.2,  0.151
    )

    if (baseline_id < 1 || baseline_id > 7) {
        return(sprintf("ERROR: baseline_id=%g out of range [1,7]", baseline_id))
    }

    lambda_ref = table2_lambdas[baseline_id, .]'
    param_names = ("time", "unit", "nn")

    if (verbose) {
        printf("\n{txt}{hline 60}\n")
        printf("{txt}Lambda validation - application %g\n", baseline_id)
        printf("{txt}{hline 60}\n")
    }

    pass_count = 0
    failure_msg = ""

    for (j = 1; j <= 3; j++) {
        lambda_p = lambda_ref[j]
        lambda_i = lambda_impl[j]

        if (verbose) {
            printf("{txt}lambda_%s: reference=%f, estimated=%f",
                   param_names[j], lambda_p, lambda_i)
        }

        if (lambda_p < 0.01) {
            /* Near-zero reference: absolute error only */
            abs_err = abs(lambda_i - lambda_p)

            if (abs_err <= 0.05) {
                if (verbose) printf(", abs_err=%f [pass]\n", abs_err)
                pass_count++
            }
            else {
                if (verbose) printf(", abs_err=%f [fail]\n", abs_err)
                failure_msg = sprintf("FAIL: lambda_%s abs_err=%f",
                                      param_names[j], abs_err)
                break
            }
        }
        else {
            /* Dual-tolerance: relative error AND absolute error */
            rel_err = abs(lambda_i - lambda_p) / lambda_p
            abs_err = abs(lambda_i - lambda_p)

            if (rel_err <= 0.10 && abs_err <= 0.05) {
                if (verbose) printf(", rel=%f%%, abs=%f [pass]\n",
                                    rel_err * 100, abs_err)
                pass_count++
            }
            else {
                if (verbose) printf(", rel=%f%%, abs=%f [fail]\n",
                                    rel_err * 100, abs_err)
                if (rel_err > 0.10) {
                    failure_msg = sprintf("FAIL: lambda_%s rel_err=%f%%",
                                          param_names[j], rel_err * 100)
                }
                else {
                    failure_msg = sprintf("FAIL: lambda_%s abs_err=%f",
                                          param_names[j], abs_err)
                }
                break
            }
        }
    }

    if (pass_count == 3) {
        if (verbose) {
            printf("{txt}{hline 60}\n")
            printf("{txt}Result: PASS (3/3 components within tolerance)\n")
            printf("{txt}{hline 60}\n\n")
        }
        return("PASS")
    }
    else {
        if (verbose) {
            printf("{txt}{hline 60}\n")
            printf("{txt}Result: %s\n", failure_msg)
            printf("{txt}{hline 60}\n\n")
        }
        return(failure_msg)
    }
}

/*──────────────────────────────────────────────────────────────────────────────
  get_table2_lambda()

  Returns the reference LOOCV-selected regularization triplet for a given
  empirical application.

  Arguments
    baseline_id   scalar in {1,...,7}

  Returns
    3 x 1 real colvector [lambda_time; lambda_unit; lambda_nn]
──────────────────────────────────────────────────────────────────────────────*/

real colvector function get_table2_lambda(real scalar baseline_id)
{
    real matrix table2_lambdas

    table2_lambdas = (
        0.1,  0.0,  0.9   \
        0.35, 1.6,  0.011 \
        0.4,  0.3,  0.006 \
        0.2,  1.2,  0.011 \
        0.35, 0.0,  0.006 \
        0.4,  0.25, 0.011 \
        0.2,  0.2,  0.151
    )

    if (baseline_id < 1 || baseline_id > 7) {
        errprintf("get_table2_lambda(): baseline_id=%g out of range [1,7]\n",
                  baseline_id)
        _error(3300)
    }

    return(table2_lambdas[baseline_id, .]')
}

/*──────────────────────────────────────────────────────────────────────────────
  get_table2_rmse()

  Returns the reference out-of-sample LOOCV RMSE (root mean squared error
  of counterfactual prediction) for a given empirical application.

  Arguments
    baseline_id   scalar in {1,...,7}

  Returns
    real scalar   RMSE
──────────────────────────────────────────────────────────────────────────────*/

real scalar function get_table2_rmse(real scalar baseline_id)
{
    real colvector table2_rmse

    table2_rmse = (
        0.025 \
        0.203 \
        0.023 \
        0.025 \
        0.041 \
        0.085 \
        0.115
    )

    if (baseline_id < 1 || baseline_id > 7) {
        errprintf("get_table2_rmse(): baseline_id=%g out of range [1,7]\n",
                  baseline_id)
        _error(3300)
    }

    return(table2_rmse[baseline_id])
}

end
