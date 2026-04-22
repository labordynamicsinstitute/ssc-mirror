*! chse_fliptime v1.0.1  18apr2025  Nityahapani
*! Leadership flip time t* and oscillation condition
*! t* = (1/mu_tilde)*ln((h0-0.5)/epsilon)

program define chse_fliptime, rclass
    version 14.0
    syntax , MU(string) ETA(string) KAPPA(string) ///
             [RBAR(real 1.0) H0(string) EPSilon(real 0.01) ///
              GENerate(name) replace]

    if `epsilon' <= 0 | `epsilon' >= 0.5 {
        di as error "epsilon() must be in (0, 0.5)"
        exit 198
    }

    // --- parse mu, eta, kappa ---
    foreach arg in mu eta kappa {
        capture confirm number ``arg''
        local `arg'_is_scalar = (_rc == 0)
        if ``arg'_is_scalar' local `arg'_val = ``arg''
        else confirm variable ``arg''
    }

    // --- parse h0 (default 0.75) ---
    if "`h0'" == "" {
        local h0_is_scalar 1
        local h0_val = 0.75
    }
    else {
        capture confirm number `h0'
        local h0_is_scalar = (_rc == 0)
        if `h0_is_scalar' local h0_val = `h0'
        else confirm variable `h0'
    }

    local all_scalar = `mu_is_scalar' & `eta_is_scalar' & ///
                       `kappa_is_scalar' & `h0_is_scalar'

    // ----------------------------------------------------------------
    // SCALAR PATH: pure arithmetic, no dataset access
    // ----------------------------------------------------------------
    if `all_scalar' {
        local disc = `mu_val'^2 - 4 * `eta_val' * `kappa_val'
        local oscillates = (`disc' < 0)

        if `disc' >= 0 {
            local mu_tilde = max((`mu_val' - sqrt(`disc')) / 2, 1e-8)
        }
        else {
            local mu_tilde = `mu_val' / 2
            local imag     = sqrt(-`disc') / 2
            local period   = (2 * _pi) / `imag'
        }

        local hstar = min(1, max(0, ///
            0.5 + (`eta_val' - `kappa_val' * `rbar') / `mu_val'))

        if !`oscillates' & `hstar' > 0.5 + `epsilon' {
            local t_star_val .
            local regime "stable"
            local t_display "inf (stable)"
        }
        else {
            local margin = `h0_val' - 0.5
            if `margin' <= 0 {
                local t_star_val 0
                local regime "oscillatory"
                local t_display "0 (h0 at or below 0.5)"
            }
            else if `mu_tilde' < 1e-10 {
                local t_star_val .
                local t_display "inf (mu_tilde ~ 0)"
                local regime "indeterminate"
            }
            else {
                local t_star_val = (1/`mu_tilde') * ln(`margin'/`epsilon')
                local regime = cond(`oscillates', "oscillatory", "stable_node")
                local t_display = string(`t_star_val', "%10.4f")
            }
        }

        return scalar t_star      = `t_star_val'
        return scalar discriminant = `disc'
        return scalar mu_tilde    = `mu_tilde'
        return scalar h_star      = `hstar'
        return scalar oscillates  = `oscillates'
        return scalar h0          = `h0_val'
        return scalar epsilon     = `epsilon'
        return local  regime        "`regime'"
        if `oscillates' return scalar period = `period'

        di as text _newline "CHSE Leadership Flip Time"
        di as text "  mu = " as result `mu_val' ///
            as text "   eta = " as result `eta_val' ///
            as text "   kappa = " as result `kappa_val' ///
            as text "   h0 = " as result `h0_val'
        di as text "  h*             = " as result %8.4f `hstar'
        di as text "  discriminant   = " as result %8.4f `disc'
        di as text "  oscillates     = " as result `oscillates'
        if `oscillates' {
            di as text "  period         = " as result %8.4f `period'
        }
        di as text "  mu_tilde       = " as result %8.4f `mu_tilde'
        di as text "  t*             = " as result "`t_display'"
        di as text "  regime         = " as result "`regime'"
        exit 0
    }

    // ----------------------------------------------------------------
    // VARIABLE PATH
    // ----------------------------------------------------------------
    local stub   = cond("`generate'" != "", "`generate'", "chse")
    local tvar   "`stub'_tstar"
    local discvar "`stub'_disc"
    local oscvar  "`stub'_oscillates"

    if "`replace'" == "" {
        foreach v in `tvar' `discvar' `oscvar' {
            capture confirm new variable `v'
            if _rc {
                di as error "Variable `v' already exists. Use replace."
                exit 110
            }
        }
    }
    else {
        foreach v in `tvar' `discvar' `oscvar' {
            capture drop `v'
        }
    }

    quietly {
        tempvar mu_t eta_t kappa_t h0_t disc_t mu_tilde_t hstar_t margin_t

        if `mu_is_scalar'    gen double `mu_t'    = `mu_val'
        else                  gen double `mu_t'    = `mu'
        if `eta_is_scalar'   gen double `eta_t'   = `eta_val'
        else                  gen double `eta_t'   = `eta'
        if `kappa_is_scalar' gen double `kappa_t' = `kappa_val'
        else                  gen double `kappa_t' = `kappa'
        if `h0_is_scalar'    gen double `h0_t'    = `h0_val'
        else                  gen double `h0_t'    = `h0'

        gen double `disc_t' = `mu_t'^2 - 4*`eta_t'*`kappa_t'
        gen double `discvar' = `disc_t'
        label variable `discvar' "Discriminant mu^2 - 4*eta*kappa"

        gen byte `oscvar' = (`disc_t' < 0)
        label variable `oscvar' "Oscillation condition (1=yes)"

        gen double `mu_tilde_t' = cond(`disc_t' >= 0, ///
            max((`mu_t' - sqrt(abs(`disc_t')))/2, 1e-8), ///
            `mu_t'/2)

        gen double `hstar_t' = min(1, max(0, ///
            0.5 + (`eta_t' - `kappa_t'*`rbar') / `mu_t'))
        gen double `margin_t' = `h0_t' - 0.5

        gen double `tvar' = .
        replace `tvar' = 0 if `margin_t' <= 0
        replace `tvar' = . if !`oscvar' & `hstar_t' > 0.5 + `epsilon'
        replace `tvar' = (1/`mu_tilde_t') * ln(`margin_t'/`epsilon') ///
            if `margin_t' > 0 & !(!`oscvar' & `hstar_t' > 0.5 + `epsilon')
        label variable `tvar' "Leadership flip time t*"
    }

    di as text _newline ///
        "Generated: " as result "`tvar'" ///
        as text "  " as result "`discvar'" ///
        as text "  " as result "`oscvar'"
end
