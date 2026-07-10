*! trop_handle_error -- Map plugin error codes to Stata return codes

/*
    trop_handle_error

    Maps numeric error codes returned by the compiled plugin to
    corresponding Stata return codes (rc) and displays diagnostic
    messages.

    Error code table:

      Code  Stata rc  Condition
      ----  --------  -----------------------------------------
       0       0      Success
       1    3300      Null pointer in plugin
       2     198      Invalid data dimensions
       3     459      No control observations
       4     459      No treated observations
       5     430      Optimization did not converge
       6     506      Singular matrix
       7     920      Memory allocation failure
       8    3301      Unrecoverable plugin error
       9     498      LOOCV failed for all combinations
      10     498      Insufficient bootstrap samples
      11    3302      General computation failure
      12     198      Invalid finite population correction (FPC)
      13     498      Singleton PSU in stratum

    Syntax:
        trop_handle_error <error_code> ["<error_msg>"]

    Stored results (c_local):
        _stata_rc      Stata return code
        _should_exit   1 = caller should abort; 0 = safe to continue
*/


program define trop_handle_error
    version 17.0
    args error_code error_msg

    // --- initialise caller-visible locals ---
    c_local _stata_rc 0
    c_local _should_exit 0

    // --- code 0: success ---
    if `error_code' == 0 {
        exit 0
    }

    // --- code 1: null pointer ---
    else if `error_code' == 1 {
        di as error _n "{bf:Internal Error: Null Pointer (Code 1)}"
        di as error "The plugin encountered a null pointer."
        if "`error_msg'" != "" {
            di as error "Details: `error_msg'"
        }
        di as txt _n "Please report this issue with:"
        di as txt "  1. Full command line used"
        di as txt "  2. Data characteristics (N, T, treatment pattern)"
        di as txt "  3. Stata version: `c(stata_version)'"
        di as txt "  4. Platform: `c(os)' `c(machine_type)'"

        c_local _stata_rc 3300
        c_local _should_exit 1
    }

    // --- code 2: invalid dimensions ---
    else if `error_code' == 2 {
        di as error _n "{bf:Invalid Data Dimensions (Code 2)}"
        di as error "The data dimensions are invalid for estimation."
        if "`error_msg'" != "" {
            di as error "Details: `error_msg'"
        }
        di as txt _n "Possible causes:"
        di as txt "  1. Panel is too small (need N >= 2, T >= 2)"
        di as txt "  2. Data contains only missing values"
        di as txt "  3. Dimension mismatch between variables"
        di as txt _n "Suggestions:"
        di as txt "  1. Check panel dimensions: {stata xtdescribe}"
        di as txt "  2. Check for missing values: {stata misstable summarize}"

        c_local _stata_rc 198
        c_local _should_exit 1
    }

    // --- code 3: no control units ---
    else if `error_code' == 3 {
        di as error _n "{bf:No Control Observations Found (Code 3)}"
        di as error "Control observations (W=0) are required for counterfactual estimation."
        if "`error_msg'" != "" {
            di as error "Details: `error_msg'"
        }
        di as txt _n "Possible causes:"
        di as txt "  1. All observations are treated (W=1)"
        di as txt "  2. Control observations filtered out by [if]/[in]"
        di as txt "  3. Control observations have missing outcome values"
        di as txt _n "Suggestions:"
        di as txt "  1. Check treatment distribution: {stata tab treatvar}"
        di as txt "  2. Verify sample selection: {stata count if treatvar==0}"

        c_local _stata_rc 459
        c_local _should_exit 1
    }

    // --- code 4: no treated units ---
    else if `error_code' == 4 {
        di as error _n "{bf:No Treated Observations Found (Code 4)}"
        di as error "Treated observations (W=1) are required for treatment effect estimation."
        if "`error_msg'" != "" {
            di as error "Details: `error_msg'"
        }
        di as txt _n "Possible causes:"
        di as txt "  1. All observations are control (W=0)"
        di as txt "  2. Treated observations filtered out by [if]/[in]"
        di as txt "  3. Treated observations have missing outcome values"
        di as txt _n "Suggestions:"
        di as txt "  1. Check treatment distribution: {stata tab treatvar}"
        di as txt "  2. Verify sample selection: {stata count if treatvar==1}"

        c_local _stata_rc 459
        c_local _should_exit 1
    }

    // --- code 5: convergence failure ---
    else if `error_code' == 5 {
        di as error _n "{bf:Optimization Did Not Converge (Code 5)}"
        di as error "The alternating minimization algorithm did not converge."
        if "`error_msg'" != "" {
            di as error "Details: `error_msg'"
        }
        di as txt _n "Possible causes:"
        di as txt "  1. Tolerance too tight for the data"
        di as txt "  2. Maximum iterations too low"
        di as txt "  3. Ill-conditioned data (extreme values)"
        di as txt _n "Suggestions:"
        di as txt "  1. Increase max iterations: {stata trop ..., maxiter(500)}"
        di as txt "  2. Relax tolerance: {stata trop ..., tol(1e-4)}"
        di as txt "  3. Check for outliers: {stata summarize depvar, detail}"
        di as txt "  4. Try a different regularisation grid"

        c_local _stata_rc 430
        c_local _should_exit 1
    }

    // --- code 6: singular matrix ---
    else if `error_code' == 6 {
        di as error _n "{bf:Matrix is Singular (Code 6)}"
        di as error "A matrix operation failed due to singularity."
        if "`error_msg'" != "" {
            di as error "Details: `error_msg'"
        }
        di as txt _n "Possible causes:"
        di as txt "  1. Perfect collinearity in the data"
        di as txt "  2. Constant outcome variable"
        di as txt "  3. Degenerate panel structure"
        di as txt _n "Suggestions:"
        di as txt "  1. Check outcome variance: {stata summarize depvar}"
        di as txt "  2. Check for constant units or periods"
        di as txt "  3. Increase lambda_nn to add regularisation"

        c_local _stata_rc 506
        c_local _should_exit 1
    }

    // --- code 7: out of memory ---
    else if `error_code' == 7 {
        di as error _n "{bf:Memory Allocation Failed (Code 7)}"
        di as error "Insufficient memory for the computation."
        if "`error_msg'" != "" {
            di as error "Details: `error_msg'"
        }
        di as txt _n "Possible causes:"
        di as txt "  1. Panel size (N*T) exceeds available memory"
        di as txt "  2. Too many bootstrap replications"
        di as txt "  3. System memory exhausted"
        di as txt _n "Suggestions:"
        di as txt "  1. Reduce sample size if possible"
        di as txt "  2. Reduce bootstrap replications: {stata trop ..., bootstrap(100)}"
        di as txt "  3. Reduce panel dimensions to lower memory usage"
        di as txt "  4. Close other applications to free memory"

        c_local _stata_rc 920
        c_local _should_exit 1
    }

    // --- code 8: unrecoverable plugin error ---
    else if `error_code' == 8 {
        di as error _n "{bf:Internal Plugin Error (Code 8)}"
        di as error "The compiled plugin encountered an unrecoverable error."
        if "`error_msg'" != "" {
            di as error "Details: `error_msg'"
        }
        di as txt _n "Please report this issue with:"
        di as txt "  1. Full command line used"
        di as txt "  2. Data characteristics (N, T, treatment pattern)"
        di as txt "  3. Stata version: `c(stata_version)'"
        di as txt "  4. Platform: `c(os)' `c(machine_type)'"
        di as txt "  5. The error message above"

        c_local _stata_rc 3301
        c_local _should_exit 1
    }

    // --- code 9: LOOCV failure ---
    else if `error_code' == 9 {
        di as error _n "{bf:LOOCV Failed for All Lambda Combinations (Code 9)}"
        di as error "Leave-one-out cross-validation failed for every hyperparameter combination."
        if "`error_msg'" != "" {
            di as error "Details: `error_msg'"
        }
        di as txt _n "Possible causes:"
        di as txt "  1. Data too sparse for LOOCV"
        di as txt "  2. Lambda grids not suitable for the data"
        di as txt "  3. Numerical instability in the data"
        di as txt _n "Suggestions:"
        di as txt "  1. Supply a broader lambda grid"
        di as txt "  2. Use custom grids with larger values:"
        di as txt "     {stata trop ..., lambda_nn_grid(0.1 1 10)}"
        di as txt "  3. Check data quality: {stata xtdescribe}"

        c_local _stata_rc 498
        c_local _should_exit 1
    }

    // --- code 10: bootstrap failure ---
    else if `error_code' == 10 {
        di as error _n "{bf:Bootstrap Sample Insufficient (Code 10)}"
        di as error "Bootstrap inference failed due to insufficient valid samples."
        if "`error_msg'" != "" {
            di as error "Details: `error_msg'"
        }
        di as txt _n "Possible causes:"
        di as txt "  1. Too few treated observations for resampling"
        di as txt "  2. Bootstrap samples produce degenerate estimates"
        di as txt "  3. Data structure not suitable for bootstrap"
        di as txt _n "Suggestions:"
        di as txt "  1. Reduce bootstrap replications: {stata trop ..., bootstrap(100)}"
        di as txt "  2. Check treated sample size: {stata count if treatvar==1}"
        di as txt "  3. Consider analytical standard errors (no bootstrap)"

        c_local _stata_rc 498
        c_local _should_exit 1
    }

    // --- code 11: general computation error ---
    else if `error_code' == 11 {
        di as error _n "{bf:Computation Failed (Code 11)}"
        di as error "A general computation error occurred."
        if "`error_msg'" != "" {
            di as error "Details: `error_msg'"
        }
        di as txt _n "Possible causes:"
        di as txt "  1. Numerical overflow or underflow"
        di as txt "  2. Invalid intermediate results"
        di as txt "  3. Data contains extreme values"
        di as txt _n "Suggestions:"
        di as txt "  1. Check for extreme values: {stata summarize depvar, detail}"
        di as txt "  2. Standardise the outcome variable"
        di as txt "  3. Try a different lambda grid"

        c_local _stata_rc 3302
        c_local _should_exit 1
    }

    // --- code 12: invalid FPC ---
    else if `error_code' == 12 {
        di as error _n "{bf:Invalid Finite Population Correction (Code 12)}"
        di as error "The FPC variable contains invalid values."
        if "`error_msg'" != "" {
            di as error "Details: `error_msg'"
        }
        di as txt _n "Possible causes:"
        di as txt "  1. FPC values are not in the valid range (0, 1] or integers > n"
        di as txt "  2. FPC variable contains missing values"
        di as txt "  3. FPC is constant and uninformative"
        di as txt _n "Suggestions:"
        di as txt "  1. Check FPC values: {stata summarize fpcvar, detail}"
        di as txt "  2. Ensure FPC > 0 for all strata"
        di as txt "  3. Remove the fpc() option if not needed"

        c_local _stata_rc 198
        c_local _should_exit 1
    }

    // --- code 13: singleton PSU ---
    else if `error_code' == 13 {
        di as error _n "{bf:Singleton PSU Detected (Code 13)}"
        di as error "One or more strata contain only a single PSU."
        if "`error_msg'" != "" {
            di as error "Details: `error_msg'"
        }
        di as txt _n "Possible causes:"
        di as txt "  1. Stratum has only one primary sampling unit"
        di as txt "  2. PSU-strata mapping is incorrect"
        di as txt _n "Suggestions:"
        di as txt "  1. Use singleunit(centered) to handle lonely PSUs"
        di as txt "  2. Check strata/PSU structure: {stata tab stratavar psuvar}"
        di as txt "  3. Consider collapsing small strata"

        c_local _stata_rc 498
        c_local _should_exit 1
    }

    // --- unrecognised error code ---
    else {
        di as error _n "{bf:Unknown Error (Code `error_code')}"
        if "`error_msg'" != "" {
            di as error "Details: `error_msg'"
        }
        di as txt _n "This is an unexpected error code. Please report this issue."

        c_local _stata_rc 3303
        c_local _should_exit 1
    }
end
