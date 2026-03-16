*! tca.ado — Transmission Channel Analysis for Stata
*! Version 1.0.0
*! Reference: Wegner, Lieb, Smeekes (2025) arXiv:2405.18987
*! Parallel implementation to tca-matlab-toolbox
*!
*! Syntax:
*!   tca , phi0(matname) ar(matname) horizon(#) from(#) ///
*!        intermediates(numlist) [order(numlist) mode(string) ///
*!        target(#) varnames(string) graph validate store(string)]

program define tca, rclass
    version 14
    syntax , PHI0(name) AR(name) HORizon(integer) FROM(integer) ///
            INTermediates(numlist) ///
            [ORDer(numlist) MODE(string) TARGET(integer 0) ///
             VARNames(string) GRaph VALidate STOre(string) ///
             ALLhorizons]

    // ============================================================
    // Validation
    // ============================================================
    confirm matrix `phi0'
    confirm matrix `ar'

    local K = rowsof(`phi0')
    local Kc = colsof(`phi0')
    if `K' != `Kc' {
        di as error "phi0 must be square (K x K)"
        exit 198
    }

    local ar_cols = colsof(`ar')
    local ar_rows = rowsof(`ar')
    if `ar_rows' != `K' {
        di as error "ar must have K rows matching phi0"
        exit 198
    }
    if mod(`ar_cols', `K') != 0 {
        di as error "ar columns must be a multiple of K (K*p for p lags)"
        exit 198
    }
    local p = `ar_cols' / `K'

    if `from' < 1 | `from' > `K' {
        di as error "from must be between 1 and K"
        exit 198
    }

    if `horizon' < 1 {
        di as error "horizon must be >= 1"
        exit 198
    }

    // Default ordering
    if "`order'" == "" {
        forvalues i = 1/`K' {
            local order `order' `i'
        }
    }

    // Default mode
    if "`mode'" == "" {
        local mode "overlapping"
    }

    // Validate mode
    if !inlist("`mode'", "overlapping", "exhaustive_3way", "exhaustive_4way") {
        di as error `"mode must be "overlapping", "exhaustive_3way", or "exhaustive_4way""'
        exit 198
    }

    // Check intermediates count for exhaustive modes
    local n_int : word count `intermediates'
    if ("`mode'" == "exhaustive_3way" | "`mode'" == "exhaustive_4way") & `n_int' != 2 {
        di as error "`mode' requires exactly 2 intermediate variables"
        exit 198
    }

    // Default target (first intermediate's response)
    if `target' == 0 {
        local target : word 1 of `intermediates'
        di as text "(target variable not specified; showing variable `target')"
    }

    // Variable names
    if "`varnames'" == "" {
        forvalues i = 1/`K' {
            local varnames `varnames' Var`i'
        }
    }
    local nvn : word count `varnames'
    if `nvn' != `K' {
        di as error "varnames must have `K' names"
        exit 198
    }

    // ============================================================
    // Load Mata library if needed
    // ============================================================
    // Check if tca_makeLD is defined in Mata
    capture mata: mata which tca_makeLD()
    if _rc {
        // Try to find and run tca.mata
        capture findfile tca.mata
        if !_rc {
            qui do "`r(fn)'"
        }
        else {
            // Try current directory
            local mata_dir = c(pwd)
            capture confirm file "`mata_dir'/tca.mata"
            if !_rc {
                qui do "`mata_dir'/tca.mata"
            }
            else {
                // Try ADOPATH
                qui findfile tca.ado
                local ado_dir = subinstr("`r(fn)'", "tca.ado", "", 1)
                capture confirm file "`ado_dir'tca.mata"
                if !_rc {
                    qui do "`ado_dir'tca.mata"
                }
                else {
                    di as error "Cannot find tca.mata — place it alongside tca.ado"
                    exit 601
                }
            }
        }
    }

    // ============================================================
    // Prepare Mata matrices
    // ============================================================
    // Convert order to Mata vector
    tempname order_mat inter_mat
    local norder : word count `order'
    matrix `order_mat' = J(1, `norder', 0)
    forvalues i = 1/`norder' {
        local oi : word `i' of `order'
        matrix `order_mat'[1, `i'] = `oi'
    }

    // Convert intermediates to Mata vector
    matrix `inter_mat' = J(1, `n_int', 0)
    forvalues i = 1/`n_int' {
        local ii : word `i' of `intermediates'
        matrix `inter_mat'[1, `i'] = `ii'
    }

    // ============================================================
    // Display header
    // ============================================================
    di as text ""
    di as text "{hline 70}"
    di as result "Transmission Channel Analysis (TCA)"
    di as text "{hline 70}"
    di as text "Reference : Wegner, Lieb & Smeekes (2025)"
    di as text "Variables : K = `K', Lags = `p', Horizon = `horizon'"
    di as text "Shock from: " as result "`: word `from' of `varnames''" ///
       as text " (variable `from')"
    di as text "Mode      : " as result "`mode'"
    di as text "Channels  : " as result "`intermediates'"
    di as text "{hline 70}"

    // ============================================================
    // Run TCA in Mata
    // ============================================================

    // Validate additivity if requested
    if "`validate'" != "" {
        di as text ""
        mata: {
            real matrix _Phi0, _As_flat, _B, _Omega
            real rowvector _order
            string rowvector _vn
            real scalar _K, _h, _from

            _Phi0    = st_matrix("`phi0'")
            _As_flat = st_matrix("`ar'")
            _K       = `K'
            _h       = `horizon'
            _from    = `from'
            _order   = st_matrix("`order_mat'")

            _vn = J(1, _K, "")
            _vn = tokens(st_local("varnames"))

            pointer(real matrix) rowvector _As
            real scalar _p, _i
            _p = cols(_As_flat) / _K
            _As = J(1, _p, NULL)
            for (_i = 1; _i <= _p; _i++) {
                _As[_i] = &(_As_flat[., ((_i-1)*_K+1)..(_i*_K)])
            }

            tca_makeSystemsForm(_Phi0, _As, _h, _order, _B, _Omega)
            (void) tca_validate_additivity(_from, _B, _Omega, _K, _h, _order, _vn)
        }
    }

    // Main TCA analysis
    mata: {
        real matrix _Phi0, _As_flat, _B, _Omega
        real rowvector _order, _inter
        string rowvector _vn
        string scalar _mode
        real scalar _K, _h, _from, _target
        struct tca_result scalar _res

        _Phi0    = st_matrix("`phi0'")
        _As_flat = st_matrix("`ar'")
        _K       = `K'
        _h       = `horizon'
        _from    = `from'
        _target  = `target'
        _order   = st_matrix("`order_mat'")
        _inter   = st_matrix("`inter_mat'")
        _mode    = st_local("mode")

        _vn = tokens(st_local("varnames"))

        // Build systems form
        pointer(real matrix) rowvector _As
        real scalar _p, _i
        _p = cols(_As_flat) / _K
        _As = J(1, _p, NULL)
        for (_i = 1; _i <= _p; _i++) {
            _As[_i] = &(_As_flat[., ((_i-1)*_K+1)..(_i*_K)])
        }

        tca_makeSystemsForm(_Phi0, _As, _h, _order, _B, _Omega)

        // Dimensions info
        printf("{txt}Systems form: B is %g x %g, Omega is %g x %g\n",
               rows(_B), cols(_B), rows(_Omega), cols(_Omega))

        // Run TCA
        _res = tca_analyze(_from, _B, _Omega, _inter, _K, _h, _order, _mode, _vn)

        // Display results
        real scalar _show_all
        _show_all = (st_local("allhorizons") != "")
        tca_display_result(_res, _target, _vn, _show_all)

        // Store in Stata
        tca_store_results(_res, _target, "tca")

        // Also store as return values
        st_matrix("r(irf_total)", _res.irf_total)
        real scalar _c
        real matrix _ch_mat
        for (_c = 1; _c <= _res.n_channels; _c++) {
            _ch_mat = *_res.irf_channels[_c]
            st_matrix("r(irf_ch" + strofreal(_c) + ")", _ch_mat)
        }
        st_numscalar("r(n_channels)", _res.n_channels)
        st_numscalar("r(K)", _K)
        st_numscalar("r(horizon)", _h)
        st_numscalar("r(from)", _from)
    }

    // ============================================================
    // Store return values
    // ============================================================
    return scalar n_channels = tca_nch
    return scalar K = `K'
    return scalar horizon = `horizon'
    return scalar from = `from'
    return local mode "`mode'"
    forvalues c = 1/$tca_nch {
        return local ch`c'name "${tca_chname`c'}"
    }
    return matrix irf_total = tca_total

    // Return channel matrices
    forvalues c = 1/$tca_nch {
        capture confirm matrix tca_ch`c'
        if !_rc {
            return matrix irf_ch`c' = tca_ch`c'
        }
    }

    // ============================================================
    // Graph if requested
    // ============================================================
    if "`graph'" != "" {
        _tca_graph, target(`target') horizon(`horizon') ///
            mode("`mode'") nch(${tca_nch}) ///
            varnames("`varnames'") from(`from')
    }

end

// ============================================================
// Graphing subprogram
// ============================================================
program define _tca_graph
    syntax , TARGET(integer) HORIZON(integer) MODE(string) ///
             NCH(integer) VARNAMES(string) FROM(integer)

    local target_name : word `target' of `varnames'
    local from_name : word `from' of `varnames'

    // Create temporary dataset
    preserve
    clear
    qui set obs `= `horizon' + 1'
    qui gen h = _n - 1

    // Total IRF
    tempname total_mat
    capture matrix `total_mat' = r(irf_total)
    if _rc {
        matrix `total_mat' = tca_total
    }
    qui gen total = .
    forvalues t = 1/`= `horizon' + 1' {
        qui replace total = `total_mat'[`t', `target'] in `t'
    }

    // Channel IRFs
    forvalues c = 1/`nch' {
        qui gen ch`c' = .
        tempname ch_mat
        capture matrix `ch_mat' = r(irf_ch`c')
        if _rc {
            matrix `ch_mat' = tca_ch`c'
        }
        forvalues t = 1/`= `horizon' + 1' {
            qui replace ch`c' = `ch_mat'[`t', `target'] in `t'
        }
    }

    // Build graph
    local ch_plots ""
    local legend_order ""
    local colors "blue red green orange purple cyan magenta"
    forvalues c = 1/`nch' {
        local col : word `c' of `colors'
        local ch_plots `ch_plots' (bar ch`c' h, color(`col'%60) barw(0.8))
        local chname "${tca_chname`c'}"
        local legend_order `legend_order' `c' "`chname'"
    }
    local n_leg = `nch' + 1
    local legend_order `legend_order' `n_leg' "Total IRF"

    twoway `ch_plots' ///
        (line total h, lcolor(black) lwidth(thick)) , ///
        title("TCA: `target_name' response to `from_name' shock") ///
        subtitle("Mode: `mode'") ///
        xtitle("Horizon") ytitle("Response") ///
        yline(0, lcolor(gray) lpattern(dash)) ///
        legend(order(`legend_order') rows(2) size(small)) ///
        scheme(s2color) ///
        name(tca_graph, replace)

    restore
end

// ============================================================
// tca_from_var: Run TCA after Stata var/svar estimation
// ============================================================
program define tca_from_var, rclass
    version 14
    syntax , FROM(integer) INTermediates(numlist) ///
            [HORizon(integer 20) ORDer(numlist) MODE(string) ///
             TARGET(integer 0) GRaph VALidate ALLhorizons]

    // Get VAR info
    if "`e(cmd)'" != "var" & "`e(cmd)'" != "svar" {
        di as error "tca_from_var requires prior var or svar estimation"
        exit 301
    }

    local K = e(neqs)
    local p = e(mlag)
    local depvar "`e(depvar)'"
    local varnames ""
    forvalues i = 1/`K' {
        local v : word `i' of `depvar'
        local varnames `varnames' `v'
    }

    // Extract AR matrices
    tempname A_all
    matrix `A_all' = J(`K', `K' * `p', 0)

    forvalues lag = 1/`p' {
        forvalues eq = 1/`K' {
            local eqname : word `eq' of `depvar'
            forvalues v = 1/`K' {
                local vname : word `v' of `depvar'
                capture local b = _b[`eqname':L`lag'.`vname']
                if !_rc {
                    matrix `A_all'[`eq', (`lag'-1)*`K' + `v'] = `b'
                }
            }
        }
    }

    // Extract Sigma and compute Cholesky
    tempname Sigma Phi0
    matrix `Sigma' = e(Sigma)
    matrix `Phi0' = cholesky(`Sigma')

    // Run TCA
    if "`order'" == "" {
        forvalues i = 1/`K' {
            local order `order' `i'
        }
    }

    if "`mode'" == "" local mode "overlapping"
    if `target' == 0 {
        local target : word 1 of `intermediates'
    }

    local opts "phi0(`Phi0') ar(`A_all') horizon(`horizon') from(`from')"
    local opts "`opts' intermediates(`intermediates') order(`order')"
    local opts "`opts' mode(`mode') target(`target') varnames(`varnames')"
    if "`graph'" != "" local opts "`opts' graph"
    if "`validate'" != "" local opts "`opts' validate"
    if "`allhorizons'" != "" local opts "`opts' allhorizons"

    tca , `opts'

    // Pass through returns
    return add
end
