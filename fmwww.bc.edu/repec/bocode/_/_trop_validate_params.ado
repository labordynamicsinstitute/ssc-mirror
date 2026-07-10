*! Input validation for trop estimation options
program define _trop_validate_params
    version 17.0
    syntax , Depvar(varname) Treatvar(varname) ///
             Panelvar(varname) Timevar(varname) ///
             Method(string) Grid_style(string) ///
             [LAMbda_time_grid(string) LAMbda_unit_grid(string) ///
              LAMbda_nn_grid(string) BOOTstrap(integer 0) ///
              BSalpha(real 0.05) TOL(real 1e-6) MAXiter(integer 500) ///
              SEED(integer -1) ///
              TOUSE(varname)]

    // --- confirm required variables exist in the dataset ---

    capture confirm variable `depvar'
    if _rc {
        di as error "Variable not found: `depvar'"
        exit 111
    }

    capture confirm variable `treatvar'
    if _rc {
        di as error "Variable not found: `treatvar'"
        exit 111
    }

    capture confirm variable `panelvar'
    if _rc {
        di as error "Variable not found: `panelvar'"
        exit 111
    }

    capture confirm variable `timevar'
    if _rc {
        di as error "Variable not found: `timevar'"
        exit 111
    }

    // --- method(): twostep (heterogeneous) or joint (homogeneous) ---

    if !inlist("`method'", "twostep", "joint") {
        di as error "method() must be 'twostep' or 'joint'"
        di as error "  twostep: heterogeneous effects (default)"
        di as error "  joint: homogeneous effects"
        exit 198
    }

    // --- grid_style(): regularization grid layout ---

    if !inlist("`grid_style'", "extended", "fine", "default", "custom") {
        di as error "grid_style() must be 'default', 'fine', or 'extended'"
        di as error "  default:    180 combinations (recommended)"
        di as error "  fine:       343 combinations (half-decade λ_nn, recommended for small panels)"
        di as error "  extended: 4,256 combinations (includes DID/TWFE corner λ_nn=∞)"
        di as error "  (custom grids via lambda_*_grid() options set this automatically)"
        exit 198
    }

    // --- lambda grids: all entries must be non-negative ---
    // Missing values (".") are skipped.

    if "`lambda_time_grid'" != "" {
        foreach val of local lambda_time_grid {
            if "`val'" != "." {
                local numval = real("`val'")
                if !missing(`numval') & `numval' < 0 {
                    di as error "Lambda values must be non-negative"
                    di as error "Found negative value in lambda_time_grid: `val'"
                    exit 198
                }
            }
        }
    }

    if "`lambda_unit_grid'" != "" {
        foreach val of local lambda_unit_grid {
            if "`val'" != "." {
                local numval = real("`val'")
                if !missing(`numval') & `numval' < 0 {
                    di as error "Lambda values must be non-negative"
                    di as error "Found negative value in lambda_unit_grid: `val'"
                    exit 198
                }
            }
        }
    }

    if "`lambda_nn_grid'" != "" {
        foreach val of local lambda_nn_grid {
            if "`val'" != "." {
                local numval = real("`val'")
                if !missing(`numval') & `numval' < 0 {
                    di as error "Lambda values must be non-negative"
                    di as error "Found negative value in lambda_nn_grid: `val'"
                    exit 198
                }
            }
        }
    }

    // --- bootstrap(): number of replications; 0 disables ---

    if `bootstrap' < 0 {
        di as error "bootstrap() must be non-negative"
        di as error "  0 = no bootstrap (default)"
        di as error "  >0 = number of bootstrap replications"
        exit 198
    }

    // --- bsalpha(): significance level in (0, 1) ---

    if `bsalpha' <= 0 | `bsalpha' >= 1 {
        di as error "bsalpha() must be between 0 and 1 (exclusive)"
        di as error "  Example: bsalpha(0.05) for 95% confidence interval"
        exit 198
    }

    // --- tol(): convergence tolerance, strictly positive ---

    if `tol' <= 0 {
        di as error "tol() must be positive"
        di as error "  Default: 1e-6"
        exit 198
    }

    // --- maxiter(): iteration cap, strictly positive ---

    if `maxiter' <= 0 {
        di as error "maxiter() must be positive"
        di as error "  Default: 500"
        exit 198
    }

end
