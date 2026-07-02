*! version 1.1.0  27jun2026
program define xtsurmg, eclass
    version 16
    syntax varlist(min=2 numeric) [if] [in], ///
        [CORr noHeader noTable Level(cilevel) ///
        fourier(integer 0) bootstrap(integer 0) CCE *]

    // Check if data is xtset
    capt xtset
    if _rc != 0 {
        di as error "Data must be xtset"
        error 459
    }
    local id `r(panelvar)'
    local it `r(timevar)'

    // Check variables
    confirm numeric var `varlist'

    // Mark estimation sample
    marksample touse

    qui tab `id' if `touse'
    local ngroups = r(r)
    if `ngroups' < 2 {
        di as error "At least 2 groups required for estimation"
        error 498
    }

    // Parse depvar and indepvars
    gettoken depvar indepvars: varlist

    // Set preserve flag
    local didpreserve = 0
    capture {
        preserve
        local didpreserve = 1
    }

    qui keep if `touse'
    qui keep `depvar' `indepvars' `id' `it'

    // Create time index
    qui sum `it'
    gen timeindex = `it' - r(min) + 1
    local period = r(max) - r(min) + 1

    // Generate CCE cross-section averages (by time period)
    // Includes the dependent variable and all independent variables.
    // Fourier terms are NEVER averaged (they are deterministic and identical
    // across units, so their cross-section average equals themselves).
    local cce_terms ""
    local depvar_indep `depvar' `indepvars'
    if "`cce'" != "" {
        foreach v of local depvar_indep {
            qui by `it', sort: egen double `v'_avg = mean(`v')
            local cce_terms `cce_terms' `v'_avg
        }
    }

    // Generate Fourier terms
    local fourier_terms ""
    if `fourier' > 0 {
        forval i = 1/`fourier' {
            gen double k`i'sin = sin(2*_pi*`i'*timeindex/`period')
            gen double k`i'cos = cos(2*_pi*`i'*timeindex/`period')
            local fourier_terms `fourier_terms' k`i'sin k`i'cos
        }
    }

    // Build the list of regressors that augment each group regression.
    // (CCE averages and/or Fourier terms in addition to the original indepvars.)
    local augment ""
    if "`cce'" != "" {
        local augment `augment' `cce_terms'
    }
    if `fourier' > 0 {
        local augment `augment' `fourier_terms'
    }


    qui levelsof `id', local(groups)

    if "`cce'" != "" {
        // ----- Mean Group (CCE-MG) estimation -----
        local report_vars `indepvars' `augment'
        local vars_all `report_vars' _cons
        local nvars = `: word count `vars_all''

        // Collect per-group coefficients into a matrix (ngroups x nvars).
        tempname coefs
        matrix `coefs' = J(`ngroups', `nvars', .)
        local grow = 0
        local used_groups = 0

        foreach g of local groups {
            local ++grow
            capture qui regress `depvar' `indepvars' `augment' if `id' == `g'
            if _rc == 0 {
                local ++used_groups
                tempname bg
                matrix `bg' = e(b)
                local bcols : colnames `bg'
                // Map this group's estimated coefficients to the common order.
                local jcol = 0
                foreach v of local vars_all {
                    local ++jcol
                    if colnumb(`bg', "`v'") != . {
                        matrix `coefs'[`grow', `jcol'] = `bg'[1, colnumb(`bg', "`v'")]
                    }
                }
            }
        }

        if `used_groups' < 1 {
            di as error "No group-specific regression could be estimated"
            if `didpreserve' restore
            error 498
        }

        // Compute MG mean, variance, se, z, p for each term.
        tempname mg_means mg_var mg_se mg_z mg_p
        matrix `mg_means' = J(1, `nvars', .)
        matrix `mg_var'   = J(1, `nvars', .)
        matrix `mg_se'    = J(1, `nvars', .)
        matrix `mg_z'     = J(1, `nvars', .)
        matrix `mg_p'     = J(1, `nvars', .)

        forval j = 1/`nvars' {
            local sum = 0
            local cnt = 0
            forval r = 1/`ngroups' {
                local val = `coefs'[`r', `j']
                if !missing(`val') {
                    local sum = `sum' + `val'
                    local cnt = `cnt' + 1
                }
            }
            local mean = cond(`cnt' > 0, `sum'/`cnt', .)
            local variance = 0
            if `cnt' > 1 {
                forval r = 1/`ngroups' {
                    local val = `coefs'[`r', `j']
                    if !missing(`val') {
                        local diff = `val' - `mean'
                        local variance = `variance' + `diff'*`diff'
                    }
                }
                // Non-parametric MG variance of the mean: s2 / N
                local variance = `variance' / (`cnt'*(`cnt'-1))
            }
            local se = cond(`variance' > 0, sqrt(`variance'), .)
            local z  = cond(!missing(`se'), `mean'/`se', .)
            local p  = cond(!missing(`z'), 2*normal(-abs(`z')), .)

            matrix `mg_means'[1, `j'] = `mean'
            matrix `mg_var'[1, `j']   = `variance'
            matrix `mg_se'[1, `j']    = `se'
            matrix `mg_z'[1, `j']     = `z'
            matrix `mg_p'[1, `j']     = `p'
        }

        matrix colnames `mg_means' = `vars_all'
        matrix colnames `mg_var'   = `vars_all'
        matrix colnames `mg_se'    = `vars_all'
        matrix colnames `mg_z'     = `vars_all'
        matrix colnames `mg_p'     = `vars_all'

        // ----- Header -----
        di _n as text "{hline 78}"
        if `fourier' == 0 {
            di as text "Common Correlated Effects Mean Group (CCE-MG) Estimation"
        }
        else {
            di as text "Fourier CCE Mean Group (F-CCEMG) Estimation"
        }
        di as text "{hline 78}"
        di as text "Number of groups: " as result `ngroups'
        di as text "Groups used:      " as result `used_groups'
        di as text "Time periods:     " as result `period'
        if `fourier' > 0 {
            di as text "Fourier terms:    " as result `fourier'
        }
        di as text "CCE cross-section averages: " as result "included (depvar + indepvars)"
        di as text "{hline 78}"
        di as text %12s "Variable(s)" _col(20) "  Mean coef." ///
            _col(38) "    Std. err.  " _col(40) "   z-stat." _col(70) " P>|z|"
        di as text "{hline 78}"

        local jcol = 0
        foreach v of local vars_all {
            local ++jcol
            di as text %12s "`v'" _col(20) as result %12.5f `mg_means'[1, `jcol'] ///
                _col(38) %12.5f `mg_se'[1, `jcol'] _col(40) %12.3f `mg_z'[1, `jcol'] ///
                _col(70) %6.3f `mg_p'[1, `jcol']
        }

        di as text "{hline 78}"
        di as text "Note: CCE cross-section averages of the dependent and independent"
        di as text "      variables are included as additional regressors in each unit."

        // ----- ereturn -----
        ereturn matrix mg_means = `mg_means'
        ereturn matrix mg_var   = `mg_var'
        ereturn matrix mg_se    = `mg_se'
        ereturn matrix mg_z     = `mg_z'
        ereturn matrix mg_p     = `mg_p'
        ereturn scalar groups   = `ngroups'
        ereturn scalar groups_used = `used_groups'
        ereturn scalar time     = `period'
        ereturn local estimator = cond(`fourier' > 0, "F-CCEMG", "CCEMG")
        ereturn local cce       = "yes"
        ereturn local bootstrap = "no"
        ereturn local panelvar  `id'
        ereturn local timevar   `it'

        if `didpreserve' {
            restore
        }
        exit
    }


    // Reshape data wide by group
    qui reshape wide `depvar' `indepvars' `fourier_terms', i(`it') j(`id')

    // Build equation list and track equation names
    local eqlist
    local eqnames
    local gcount = 0
    foreach g of local groups {
        local ++gcount
        local eqname "eq`gcount'"
        local eq "(`eqname':`depvar'`g' ="
        foreach v of local indepvars {
            local eq "`eq' `v'`g'"
        }
        if `fourier' > 0 {
            forval i = 1/`fourier' {
                local eq "`eq' k`i'sin`g' k`i'cos`g'"
            }
        }
        local eq "`eq')"
        local eqlist "`eqlist' `eq'"
        local eqnames "`eqnames' `eqname'"
    }

    // Run SUR (bootstrap optional)
    if `bootstrap' > 0 {
        di _n as text "Running bootstrap SUR estimation with `bootstrap' replications..."
        capture noisily bootstrap, reps(`bootstrap') seed(1234): sureg `eqlist', `corr' `header' `table' level(`level') `options'
        if _rc {
            di as error "Bootstrap failed, running standard SUR estimation instead"
            sureg `eqlist', `corr' `header' `table' level(`level') `options'
        }
    }
    else {
        sureg `eqlist', `corr' `header' `table' level(`level') `options'
    }

    // Store SUR results
    tempname b_sur V_sur
    matrix `b_sur' = e(b)
    matrix `V_sur' = e(V)
    ereturn local bootstrap = cond(`bootstrap' > 0, "yes", "no")
    if `bootstrap' > 0 {
        ereturn scalar bootstrap_reps = `bootstrap'
    }

    di _n as text "{hline 78}"
    if `fourier' == 0 {
        di as text "Seemingly Unrelated Regression - Mean Group (SURMG) Estimation"
        di as text "{hline 78}"
        di as text "Number of groups: " `ngroups'
        di as text "Time periods: " `period'
    }
    else {
        di as text "Fourier Seemingly Unrelated Regression - Mean Group (F-SURMG) Estimation"
        di as text "{hline 78}"
        di as text "Number of groups: " `ngroups'
        di as text "Time periods: " `period'
        di as text "Fourier terms: " as result `fourier'
    }

    local coefnames : colnames `b_sur'

    // Build the full list of terms to report as mean group statistics.
    local report_vars `indepvars'
    if `fourier' > 0 {
        forval i = 1/`fourier' {
            local report_vars `report_vars' k`i'sin k`i'cos
        }
    }
    local vars_all `report_vars' _cons

    tempname mg_means mg_var mg_se mg_z mg_p
    local nvars = `: word count `vars_all''
    matrix `mg_means' = J(1, `nvars', .)
    matrix `mg_var' = J(1, `nvars', .)
    matrix `mg_se' = J(1, `nvars', .)
    matrix `mg_z' = J(1, `nvars', .)
    matrix `mg_p' = J(1, `nvars', .)

    local vindex = 1

    di as text "{hline 78}"
    di as text %12s "Variable(s)" _col(20) "  Mean coef." ///
        _col(38) "    Std. err.  " _col(40) "   z-stat." _col(70) " P>|z|"
    di as text "{hline 78}"

    // Process all reported regressors (indepvars, Fourier terms)
    foreach v of local report_vars {
        local sum = 0
        local count = 0
        local coef_list ""

        foreach g of local groups {
            local c "`v'`g'"
            if colnumb(`b_sur', "`c'") != . {
                local b = `b_sur'[1, colnumb(`b_sur', "`c'")]
                local sum = `sum' + `b'
                local count = `count' + 1
                local coef_list "`coef_list' `b'"
            }
        }

        local mean = cond(`count' > 0, `sum'/`count', .)
        local variance = 0
        if `count' > 1 {
            foreach b of local coef_list {
                local diff = `b' - `mean'
                local variance = `variance' + `diff'*`diff'
            }
            local variance = `variance' / (`count'*(`count'-1))
        }

        local se = cond(`variance' > 0, sqrt(`variance'), .)
        local z = cond(!missing(`se'), `mean'/`se', .)
        local p = cond(!missing(`z'), 2*normal(-abs(`z')), .)

        matrix `mg_means'[1, `vindex'] = `mean'
        matrix `mg_var'[1, `vindex'] = `variance'
        matrix `mg_se'[1, `vindex'] = `se'
        matrix `mg_z'[1, `vindex'] = `z'
        matrix `mg_p'[1, `vindex'] = `p'

        di as text %12s "`v'" _col(20) as result %12.5f `mean' ///
            _col(38) %12.5f `se' _col(40) %12.3f `z' _col(70) %6.3f `p'

        local ++vindex
    }

    // Process constant term separately using equation names
    local sum_cons = 0
    local count_cons = 0
    local coef_list_cons ""

    foreach eq of local eqnames {
        local c "`eq':_cons"
        if colnumb(`b_sur', "`c'") != . {
            local b = `b_sur'[1, colnumb(`b_sur', "`c'")]
            local sum_cons = `sum_cons' + `b'
            local count_cons = `count_cons' + 1
            local coef_list_cons "`coef_list_cons' `b'"
        }
    }

    local mean_cons = cond(`count_cons' > 0, `sum_cons'/`count_cons', .)
    local variance_cons = 0
    if `count_cons' > 1 {
        foreach b of local coef_list_cons {
            local diff = `b' - `mean_cons'
            local variance_cons = `variance_cons' + `diff'*`diff'
        }
        local variance_cons = `variance_cons' / (`count_cons'*(`count_cons'-1))
    }

    local se_cons = cond(`variance_cons' > 0, sqrt(`variance_cons'), .)
    local z_cons = cond(!missing(`se_cons'), `mean_cons'/`se_cons', .)
    local p_cons = cond(!missing(`z_cons'), 2*normal(-abs(`z_cons')), .)

    matrix `mg_means'[1, `vindex'] = `mean_cons'
    matrix `mg_var'[1, `vindex'] = `variance_cons'
    matrix `mg_se'[1, `vindex'] = `se_cons'
    matrix `mg_z'[1, `vindex'] = `z_cons'
    matrix `mg_p'[1, `vindex'] = `p_cons'

    di as text %12s "_cons" _col(20) as result %12.5f `mean_cons' ///
        _col(38) %12.5f `se_cons' _col(40) %12.3f `z_cons' _col(70) %6.3f `p_cons'

    matrix colnames `mg_means' = `report_vars' _cons
    matrix colnames `mg_var' = `report_vars' _cons
    matrix colnames `mg_se' = `report_vars' _cons
    matrix colnames `mg_z' = `report_vars' _cons
    matrix colnames `mg_p' = `report_vars' _cons

    ereturn matrix mg_means = `mg_means'
    ereturn matrix mg_var = `mg_var'
    ereturn matrix mg_se = `mg_se'
    ereturn matrix mg_z = `mg_z'
    ereturn matrix mg_p = `mg_p'
    ereturn scalar groups = `ngroups'
    ereturn scalar time = `period'
    ereturn local estimator = cond(`fourier' > 0, "F-SURMG", "SURMG")
    ereturn local cce = "no"
    ereturn local panelvar `id'
    ereturn local timevar `it'

    di as text "{hline 78}"
    di as text "Note: Mean coef. is calculated based on SUR group-specific coefficients"

    // Safely restore
    if `didpreserve' {
        restore
    }
end
