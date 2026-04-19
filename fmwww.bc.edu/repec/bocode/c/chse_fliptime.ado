*! chse_fliptime — Leadership flip time t* and oscillation condition
*! Version 1.0.0   April 2025
*! Author: Nityahapani
*!
*! Computes the first-passage time t* at which the hierarchy belief h(t)
*! is expected to cross the 0.5 threshold from its initial value h0.
*!
*!   t* = (1 / mu_tilde) * ln( (h0 - 0.5) / epsilon )
*!
*! where mu_tilde = |Re(lambda)| is the effective decay rate from the
*! Jacobian eigenvalues lambda = (-mu +/- sqrt(mu^2 - 4*eta*kappa)) / 2.
*!
*! Oscillation condition: mu^2 < 4 * eta_bar * kappa_bar
*!
*! Syntax:
*!   chse_fliptime, mu(#) eta(#) kappa(#) [rbar(#) h0(#) epsilon(#)]
*!   chse_fliptime, mu(varname) eta(varname) kappa(varname)
*!                  [rbar(#) h0(varname|#) epsilon(#) generate(stub) replace]

program define chse_fliptime, rclass
    version 14.0
    
    syntax , MU(string) ETA(string) KAPPA(string) ///
             [RBAR(real 1.0) H0(string) EPSilon(real 0.01) ///
              GENerate(name) replace]
    
    if `epsilon' <= 0 | `epsilon' >= 0.5 {
        di as error "epsilon() must be in (0, 0.5)"
        exit 198
    }
    
    // ----------------------------------------------------------------
    // Detect scalar vs variable for mu, eta, kappa, h0
    // ----------------------------------------------------------------
    foreach arg in mu eta kappa {
        capture confirm number ``arg''
        local `arg'_is_scalar = (_rc == 0)
        if ``arg'_is_scalar' local `arg'_val = ``arg''
        else confirm variable ``arg''
    }
    
    // h0 default
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
    
    // ----------------------------------------------------------------
    // All-scalar path: return results, display table
    // ----------------------------------------------------------------
    local all_scalar = `mu_is_scalar' & `eta_is_scalar' & `kappa_is_scalar' & `h0_is_scalar'
    
    if `all_scalar' {
        // Discriminant
        local disc = `mu_val'^2 - 4 * `eta_val' * `kappa_val'
        local oscillates = (`disc' < 0)
        
        // Real part of dominant eigenvalue
        if `disc' >= 0 {
            // real eigenvalues: real parts are (-mu +/- sqrt(disc))/2
            // least negative (dominant) is (-mu + sqrt(disc))/2
            local mu_tilde = (`mu_val' - sqrt(`disc')) / 2
            // mu_tilde is the magnitude |Re(lambda)|
            if `mu_tilde' <= 0 local mu_tilde = 1e-8
        }
        else {
            // complex: Re(lambda) = -mu/2, so |Re| = mu/2
            local mu_tilde = `mu_val' / 2
        }
        
        // Period (if oscillatory)
        if `oscillates' {
            local period = (2 * _pi) / sqrt(abs(`disc')) * 2
            // Im(lambda) = sqrt(-disc)/2
            local imag = sqrt(-`disc') / 2
            local period = (2 * _pi) / `imag'
        }
        else {
            local period = .
        }
        
        // Fixed point h*
        local hstar = 0.5 + (`eta_val' - `kappa_val' * `rbar') / `mu_val'
        if `hstar' > 1 local hstar = 1
        if `hstar' < 0 local hstar = 0
        
        // Flip time
        if !`oscillates' & `hstar' > 0.5 + `epsilon' {
            // stable: h* above 0.5, never flips deterministically
            return scalar t_star    = .
            return local  regime    "stable"
            local t_display "inf (stable — h* > 0.5)"
        }
        else {
            local margin = `h0_val' - 0.5
            if `margin' <= 0 {
                return scalar t_star = 0
                return local  regime "oscillatory"
                local t_display "0 (h0 already at 0.5)"
            }
            else if `mu_tilde' < 1e-10 {
                return scalar t_star = .
                local t_display "inf (mu_tilde = 0)"
            }
            else {
                local t_star = (1 / `mu_tilde') * ln(`margin' / `epsilon')
                return scalar t_star = `t_star'
                if `oscillates' return local regime "oscillatory"
                else            return local regime "stable_node"
                local t_display = string(`t_star', "%10.4f")
            }
        }
        
        return scalar discriminant = `disc'
        return scalar mu_tilde     = `mu_tilde'
        return scalar h_star       = `hstar'
        return scalar oscillates   = `oscillates'
        if `oscillates' return scalar period = `period'
        return scalar h0           = `h0_val'
        return scalar epsilon      = `epsilon'
        
        di as text _newline "CHSE Leadership Flip Time"
        di as text "  Parameters:"
        di as text "    mu        = " as result `mu_val' ///
                   as text "   eta_bar = " as result `eta_val' ///
                   as text "   kappa_bar = " as result `kappa_val'
        di as text "    h0        = " as result `h0_val' ///
                   as text "   epsilon  = " as result `epsilon'
        di as text _newline "  Results:"
        di as text "    h*             = " as result %8.4f `hstar'
        di as text "    discriminant   = " as result %8.4f `disc'
        di as text "    oscillates     = " as result `oscillates'
        if `oscillates' {
            di as text "    period        = " as result %8.4f `period'
        }
        di as text "    mu_tilde       = " as result %8.4f `mu_tilde'
        di as text "    t*             = " as result "`t_display'"
        di as text "    regime         = " as result "`r(regime)'"
    }
    else {
    
    // ----------------------------------------------------------------
    // Variable path: generate columns
    // ----------------------------------------------------------------
    local stub = cond("`generate'" != "", "`generate'", "chse")
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
        tempvar mu_t eta_t kappa_t h0_t disc_t mu_tilde_t
        
        if `mu_is_scalar'    gen double `mu_t'    = `mu_val'
        else                 gen double `mu_t'    = `mu'
        if `eta_is_scalar'   gen double `eta_t'   = `eta_val'
        else                 gen double `eta_t'   = `eta'
        if `kappa_is_scalar' gen double `kappa_t' = `kappa_val'
        else                 gen double `kappa_t' = `kappa'
        if `h0_is_scalar'    gen double `h0_t'    = `h0_val'
        else                 gen double `h0_t'    = `h0'
        
        // Discriminant
        gen double `disc_t' = `mu_t'^2 - 4 * `eta_t' * `kappa_t'
        gen double `discvar' = `disc_t'
        label variable `discvar' "Discriminant mu^2 - 4*eta*kappa"
        
        // Oscillates
        gen byte `oscvar' = (`disc_t' < 0)
        label variable `oscvar' "Oscillation condition holds (1=yes)"
        
        // mu_tilde
        gen double `mu_tilde_t' = cond(`disc_t' >= 0, ///
            (`mu_t' - sqrt(abs(`disc_t'))) / 2, ///
            `mu_t' / 2)
        replace `mu_tilde_t' = max(`mu_tilde_t', 1e-8)
        
        // Fixed point
        tempvar hstar_t margin_t
        gen double `hstar_t' = min(1, max(0, 0.5 + (`eta_t' - `kappa_t' * `rbar') / `mu_t'))
        gen double `margin_t' = `h0_t' - 0.5
        
        // t*
        gen double `tvar' = .
        replace `tvar' = 0 if `margin_t' <= 0
        replace `tvar' = . if !`oscvar' & `hstar_t' > 0.5 + `epsilon'  // stable, no flip
        replace `tvar' = (1 / `mu_tilde_t') * ln(`margin_t' / `epsilon') ///
            if `margin_t' > 0 & ///
               !(!`oscvar' & `hstar_t' > 0.5 + `epsilon')
        label variable `tvar' "Leadership flip time t*"
    }
    
    di as text _newline ///
        "Generated: " as result "`tvar'" as text " (flip time)"
    di as text ///
        "          " as result "`discvar'" as text " (discriminant)"
    di as text ///
        "          " as result "`oscvar'" as text " (oscillation indicator)"
    
    } // end else (variable path)

end
