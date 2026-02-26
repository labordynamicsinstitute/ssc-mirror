*! _mvardlurt_bootstrap — Bootstrap engine for mvardlurt
*! Version 2.0.0 — 2026-02-24
*!
*! Implements the parametric bootstrap from Sam, McNown, Goh & Goh (2024).
*! Uses st_store/st_data approach — no tempfiles needed.
*! Recursive DGP in Mata exactly replicates EViews model a / a.solve.

capture program drop _mvardlurt_bootstrap
program define _mvardlurt_bootstrap, rclass
    version 14

    syntax varname(ts), ///
        INDEPvar(varname ts)   /// independent variable
        Plag(integer)          /// optimal dy lag length
        Qlag(integer)          /// optimal dx lag length
        Case(integer)          /// 1, 3, or 5
        REPS(integer)          /// bootstrap replications
        SEED(integer)          /// random seed

    local depvar "`varlist'"
    local indepvar "`indepvar'"
    local opt_p = `plag'
    local opt_q = `qlag'

    // =========================================================================
    // 1. SETUP
    // =========================================================================
    qui tsset
    qui count
    local TT = r(N)
    set seed `seed'

    local nocons_opt ""
    if `case' == 1 local nocons_opt "noconstant"

    local opt_lag = `opt_p' + `opt_q'

    // Build regressor strings
    local dy_lags ""
    if `opt_p' > 0 {
        forvalues j = 1/`opt_p' {
            local dy_lags "`dy_lags' L`j'.D.`depvar'"
        }
    }
    local dx_lags ""
    if `opt_q' > 0 {
        forvalues j = 1/`opt_q' {
            local dx_lags "`dx_lags' L`j'.D.`indepvar'"
        }
    }
    local det_regs ""
    if `case' == 5 {
        tempvar ttrend
        qui gen double `ttrend' = _n
        local det_regs "`ttrend'"
    }

    // Model specifications (matching EViews exactly)
    local rest_t_reg "L.`indepvar' `dy_lags' `dx_lags' `det_regs'"
    local rest_f_reg "L.`depvar' `dy_lags' `dx_lags' `det_regs'"
    local full_reg   "L.`depvar' L.`indepvar' `dy_lags' `dx_lags' `det_regs'"

    // =========================================================================
    // 2. ESTIMATE RESTRICTED MODELS & EXTRACT/RECENTER RESIDUALS
    // =========================================================================

    // t-restricted: impose y(-1) = 0
    qui regress D.`depvar' `rest_t_reg', `nocons_opt'
    tempvar resid_t
    qui predict double `resid_t', residuals
    tempname b_rest_t
    mat `b_rest_t' = e(b)
    qui su `resid_t', meanonly
    qui replace `resid_t' = `resid_t' - r(mean)

    // f-restricted: impose x(-1) = 0
    qui regress D.`depvar' `rest_f_reg', `nocons_opt'
    tempvar resid_f
    qui predict double `resid_f', residuals
    tempname b_rest_f
    mat `b_rest_f' = e(b)
    qui su `resid_f', meanonly
    qui replace `resid_f' = `resid_f' - r(mean)

    // =========================================================================
    // 3. COPY EVERYTHING TO MATA (once, before the loop)
    // =========================================================================
    // Find the column index of depvar for st_store
    qui ds `depvar'

    mata {
        // Copy data to Mata (survives any Stata data manipulation)
        _y_orig = st_data(., "`depvar'")
        _x_orig = st_data(., "`indepvar'")
        _res_t  = st_data(., "`resid_t'")
        _res_f  = st_data(., "`resid_f'")
        _TT = rows(_y_orig)

        // Compute original dx (first diff of x)
        _dx_orig = J(_TT, 1, .)
        for (_i = 2; _i <= _TT; _i++) _dx_orig[_i] = _x_orig[_i] - _x_orig[_i-1]

        // Restricted coefficients
        _b_t = st_matrix("`b_rest_t'")
        _b_f = st_matrix("`b_rest_f'")

        // Bootstrap storage
        _boot_tstat = J(`reps', 1, .)
        _boot_fstat = J(`reps', 1, .)

        // Parameters
        _op = `opt_p'
        _oq = `opt_q'
        _cv = `case'
        _si = `opt_lag' + 2
        if (_si < 3) _si = 3

        // Find depvar column index for st_store
        _depvar_idx = .
        _vnames = st_varindex("`depvar'")
        _depvar_idx = _vnames
    }

    // =========================================================================
    // 4. BOOTSTRAP LOOP
    //    Strategy: Mata generates bootstrap y, writes it to Stata via st_store,
    //    then Stata runs regress with TS operators on the bootstrap data.
    //    No tempfiles needed — we restore y_orig at the end.
    // =========================================================================
    forvalues b = 1/`reps' {
        if mod(`b', 250) == 0 | `b' == 1 {
            di as txt _col(7) "Bootstrap replication `b'/`reps'..."
        }

        // ─── Mata: Recursive DGP + write to Stata ───
        mata {
            // Joint resample with replacement
            _ri = ceil(uniform(_TT, 1) :* _TT)
            for (_i = 1; _i <= _TT; _i++) {
                if (_ri[_i] < 1) _ri[_i] = 1
                if (_ri[_i] > _TT) _ri[_i] = _TT
            }
            _rt_b = _res_t[_ri]
            _rf_b = _res_f[_ri]

            // Initialize bootstrap series from original data
            _yt = _y_orig
            _dyt = J(_TT, 1, 0)
            _yf = _y_orig
            _dyf = J(_TT, 1, 0)
            for (_i = 2; _i <= _TT; _i++) {
                _dyt[_i] = _y_orig[_i] - _y_orig[_i-1]
                _dyf[_i] = _y_orig[_i] - _y_orig[_i-1]
            }

            // ──── Recursive DGP (EViews model a / a.solve) ────
            for (_i = _si; _i <= _TT; _i++) {

                // t-test DGP: H0 pi=0, no y(-1)
                // Coef layout: [x(-1), dy(-1..p), dx(-1..q), det...]
                _val = _b_t[1] * _x_orig[_i-1]
                _ci = 2
                for (_j = 1; _j <= _op; _j++) {
                    if (_i-_j >= 1) _val = _val + _b_t[_ci] * _dyt[_i-_j]
                    _ci++
                }
                for (_k = 1; _k <= _oq; _k++) {
                    if (_i-_k >= 2) _val = _val + _b_t[_ci] * _dx_orig[_i-_k]
                    _ci++
                }
                if (_cv == 3) _val = _val + _b_t[_ci]
                else if (_cv == 5) _val = _val + _b_t[_ci] + _b_t[_ci+1]*_i
                _dyt[_i] = _val + _rt_b[_i]
                _yt[_i] = _yt[_i-1] + _dyt[_i]

                // f-test DGP: H0 delta=0, no x(-1)
                // Coef layout: [y(-1), dy(-1..p), dx(-1..q), det...]
                _val = _b_f[1] * _yf[_i-1]
                _ci = 2
                for (_j = 1; _j <= _op; _j++) {
                    if (_i-_j >= 1) _val = _val + _b_f[_ci] * _dyf[_i-_j]
                    _ci++
                }
                for (_k = 1; _k <= _oq; _k++) {
                    if (_i-_k >= 2) _val = _val + _b_f[_ci] * _dx_orig[_i-_k]
                    _ci++
                }
                if (_cv == 3) _val = _val + _b_f[_ci]
                else if (_cv == 5) _val = _val + _b_f[_ci] + _b_f[_ci+1]*_i
                _dyf[_i] = _val + _rf_b[_i]
                _yf[_i] = _yf[_i-1] + _dyf[_i]
            }

            // Write t-bootstrap y to Stata for regression
            st_store(., _depvar_idx, _yt)
        }

        // ─── t-test: regress on bootstrap data ───
        capture {
            qui regress D.`depvar' `full_reg', `nocons_opt'
        }
        if _rc == 0 {
            local bt = _b[L.`depvar'] / _se[L.`depvar']
            mata: _boot_tstat[`b'] = strtoreal(st_local("bt"))
        }

        // ─── f-test: write f-bootstrap y, then regress ───
        mata: st_store(., _depvar_idx, _yf)

        capture {
            qui regress D.`depvar' `full_reg', `nocons_opt'
        }
        if _rc == 0 {
            capture qui test L.`indepvar'
            if _rc == 0 {
                local bf = r(F)
                mata: _boot_fstat[`b'] = strtoreal(st_local("bf"))
            }
        }
    }

    // ─── Restore original y ───
    mata: st_store(., _depvar_idx, _y_orig)

    di as txt _col(7) "Bootstrap completed."
    di as txt ""

    // =========================================================================
    // 5. COMPUTE CRITICAL VALUES (all in Mata)
    // =========================================================================
    tempname tcv10 tcv05 tcv025 tcv01 fcv10 fcv05 fcv025 fcv01 nbt nbf

    mata {
        _btc = select(_boot_tstat, _boot_tstat :< .)
        _bfc = select(_boot_fstat, _boot_fstat :< .)
        _nbt = rows(_btc)
        _nbf = rows(_bfc)

        // t-test: LOWER tail (reject if observed t < cv)
        if (_nbt > 10) {
            _ts = sort(_btc, 1)
            st_numscalar("`tcv10'",  _ts[ceil(.10*_nbt)])
            st_numscalar("`tcv05'",  _ts[ceil(.05*_nbt)])
            st_numscalar("`tcv025'", _ts[ceil(.025*_nbt)])
            st_numscalar("`tcv01'",  _ts[ceil(.01*_nbt)])
        }
        else {
            st_numscalar("`tcv10'", .)
            st_numscalar("`tcv05'", .)
            st_numscalar("`tcv025'", .)
            st_numscalar("`tcv01'", .)
        }

        // F-test: UPPER tail (reject if observed F > cv)
        if (_nbf > 10) {
            _fs = sort(_bfc, 1)
            st_numscalar("`fcv10'",  _fs[ceil(.90*_nbf)])
            st_numscalar("`fcv05'",  _fs[ceil(.95*_nbf)])
            st_numscalar("`fcv025'", _fs[ceil(.975*_nbf)])
            st_numscalar("`fcv01'",  _fs[ceil(.99*_nbf)])
        }
        else {
            st_numscalar("`fcv10'", .)
            st_numscalar("`fcv05'", .)
            st_numscalar("`fcv025'", .)
            st_numscalar("`fcv01'", .)
        }

        st_numscalar("`nbt'", _nbt)
        st_numscalar("`nbf'", _nbf)
    }

    di as txt _col(5) "Valid bootstrap t-replications: " as res scalar(`nbt')
    di as txt _col(5) "Valid bootstrap F-replications: " as res scalar(`nbf')
    di as txt ""

    // Return all scalars
    return scalar t_cv10  = scalar(`tcv10')
    return scalar t_cv05  = scalar(`tcv05')
    return scalar t_cv025 = scalar(`tcv025')
    return scalar t_cv01  = scalar(`tcv01')
    return scalar f_cv10  = scalar(`fcv10')
    return scalar f_cv05  = scalar(`fcv05')
    return scalar f_cv025 = scalar(`fcv025')
    return scalar f_cv01  = scalar(`fcv01')
    return scalar B_t     = scalar(`nbt')
    return scalar B_f     = scalar(`nbf')
end
