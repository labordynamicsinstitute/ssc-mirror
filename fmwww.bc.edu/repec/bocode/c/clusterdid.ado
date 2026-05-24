*! version 1.0.1  21May2026
*! author: Wael Moussa, PhD | FHI 360
*! Unified Multi-Period Cluster RCT Power Analysis

program define clusterdid, rclass
    version 16.0
    
    // 1. Syntax Parser
syntax [, T0(integer 1) T1(integer 1) ///
         RHOJ(real 0.05) RHOT(real 0.70) ///
         M(string) N(string) POWER(string) ///
         D(string) P(string) SD(string) ///
         ALPHA(real 0.05) ALLOC(real 0.5) ///
         CROSSVAL(string) ]
              
    local p_alloc = `alloc'

    // 2. Numlist & Range Detection
    local range_count = 0
    local range_var ""
    local range_list ""
    
    foreach v in m n d p power {
        if "``v''" != "" {
            capture numlist "``v''"
            if _rc == 0 {
                local expanded_list "`r(numlist)'"
                local list_len : word count `expanded_list'
                
                local is_range = 0
                if ("`v'" == "d" | "`v'" == "p") & `list_len' > 2 {
                    local is_range = 1
                }
                else if ("`v'" != "d" & "`v'" != "p") & `list_len' > 1 {
                    local is_range = 1
                }
                
                if `is_range' == 1 {
                    local range_count = `range_count' + 1
                    local range_list "`expanded_list'"
                    if "`v'" == "d" | "`v'" == "p" {
                        local range_var "delta"
                    }
                    else {
                        local range_var "`v'"
                    }
                }
            }
        }
    }
    
    if `range_count' > 1 {
        di as err "Syntax Error: Only one parameter can be evaluated as a range at a time."
        exit 198
    }

    // 3. Continuous vs Proportion Routing & Imputation
    local is_prop = 0
    local delta ""
    local sd_val = 1.0 
    local p_anchor = 0.5
    
    if "`p'" != "" {
        local is_prop = 1
        local num_p : word count `p'
        if `num_p' >= 2 {
            local p1 : word 1 of `p'
            local p0 : word 2 of `p'
            local p_anchor = real("`p0'")
        }
        else {
            local p1 : word 1 of `p'
            local p0 = 0.5   
            local p_anchor = 0.5
        }
        if "`range_var'" != "delta" {
            local delta = abs(real("`p1'") - real("`p0'"))
            local pbar  = (real("`p1'") + real("`p0'")) / 2
            local sd_val = sqrt(`pbar' * (1 - `pbar'))
        }
    }
    else {
        if "`sd'" != "" {
            local num_sd : word count `sd'
            if `num_sd' >= 2 {
                local sd1 : word 1 of `sd'
                local sd0 : word 2 of `sd'
                local sd_val = sqrt((real("`sd1'")^2 + real("`sd0'")^2) / 2) 
            }
            else {
                local sd_val = real("`sd'")
            }
        }
        
        if "`d'" != "" & "`range_var'" != "delta" {
            local num_d : word count `d'
            if `num_d' >= 2 {
                local d1 : word 1 of `d'
                local d0 : word 2 of `d'
                local delta = abs(real("`d1'") - real("`d0'"))
            }
            else {
                local delta = real("`d'") 
            }
        }
    }

    // 4. Target Identification & Syntax Validation
    local target ""
    local missing_count = 0
    
    if "`m'" == "" {
        local target "m"
        local missing_count = `missing_count' + 1
    }
    if "`n'" == "" {
        local target "n"
        local missing_count = `missing_count' + 1
    }
    if "`d'" == "" & "`p'" == "" {
        local target "delta"
        local missing_count = `missing_count' + 1
    }
    if "`power'" == "" {
        local target "power"
        local missing_count = `missing_count' + 1
    }
    
    if `missing_count' != 1 {
        di as err "Syntax Error: You must specify exactly three of the following: m(), n(), d() [or p()], and power()."
        exit 198
    }

    // 5. Structural Math Parameters (Corrected Face Variance Tracker)
    if `t0' > 0 {
        local theta = (1 / `t0') + (1 / `t1')
        local psi   = 1 - `rhot'
    }
    else {
        local theta = 1 / `t1'
        local psi   = 1 + (`t1' - 1) * `rhot'
    }
    local z_a = invnormal(1 - `alpha'/2)

    // =========================================================================
    // BRANCH A: SCALAR EVALUATION (No Ranges Detected)
    // =========================================================================
    if `range_count' == 0 {
        
        * Solver Block
        if "`target'" == "power" {
            local z_b = `delta' * sqrt((`p_alloc'*(1-`p_alloc')*`m') / (`sd_val'^2 * `theta' * (`rhoj'*`psi' + (1-`rhoj')/`n'))) - `z_a'
            local power = normal(`z_b')
        }
        else if "`target'" == "delta" {
            local z_b = invnormal(real("`power'"))
            local delta = (`z_a' + `z_b') * `sd_val' * sqrt( (`theta') / (`p_alloc'*(1-`p_alloc')*`m') * (`rhoj'*`psi' + (1-`rhoj')/`n') )
        }
        else if "`target'" == "m" {
            local z_b = invnormal(real("`power'"))
            local m = ((`z_a' + `z_b')^2 * `sd_val'^2) / (`p_alloc'*(1-`p_alloc')*`delta'^2) * `theta' * (`rhoj'*`psi' + (1-`rhoj')/`n')
        }
        else if "`target'" == "n" {
            local z_b = invnormal(real("`power'"))
            local denom = (`p_alloc'*(1-`p_alloc')*`m'*`delta'^2) / (`sd_val'^2 * `theta' * (`z_a' + `z_b')^2) - `rhoj'*`psi'
            if `denom' <= 0 {
                di as err "Error: Target power is structurally unachievable with m = `m' clusters due to the temporal cluster variance constraint."
                exit 498
            }
            local n = (1-`rhoj') / `denom'
        }

        * Formatting Block
        local m_ceil  = ceil(`m')
        local mt      = ceil(`p_alloc' * `m_ceil')
        local mc      = `m_ceil' - `mt'
        local total_T = `t0' + `t1'
        local total_N = `total_T' * `m_ceil' * ceil(`n')

        di ""
        di as txt "{bf:Multi-Period Cluster RCT Power Analysis}"
        di as txt "Three-way error components framework (Baltagi, 2021)"
        di ""
        
        * === DESIGN ARCHITECTURE BLOCK ===
        di as txt "  Design Architecture:"
        di as txt _col(5) "Pre-treatment periods (T₀)"    _col(40) "=" as res _col(42) %10.0f `t0'
        di as txt _col(5) "Post-treatment periods (T₁)"   _col(40) "=" as res _col(42) %10.0f `t1'
        di as txt _col(5) "Treatment allocation (p)"      _col(40) "=" as res _col(42) %10.3f `p_alloc'
        di ""
        di as txt _col(5) "Cluster ICC (ρ_j)"             _col(40) "=" as res _col(42) %10.3f `rhoj'
        di as txt _col(5) "Cluster Autocorrelation (ρ_t)" _col(40) "=" as res _col(42) %10.3f `rhot'
        di ""
        if `is_prop' == 1 {
            di as txt _col(5) "Treatment Proportion (p₁)" _col(40) "=" as res _col(42) %10.3f real("`p1'")
            di as txt _col(5) "Control Proportion (p₀)"   _col(40) "=" as res _col(42) %10.3f real("`p0'")
            di as txt _col(5) "Implied Binomial Var (σ²)" _col(40) "=" as res _col(42) %10.3f `sd_val'^2
        }
        else {
            if "`target'" != "delta" {
                di as txt _col(5) "Treatment Mean (d₁)"       _col(40) "=" as res _col(42) %10.3f real("`d1'")
                di as txt _col(5) "Control Mean (d₀)"         _col(40) "=" as res _col(42) %10.3f real("`d0'")
            }
            di as txt _col(5) "Raw Standard Deviation (σ)" _col(40) "=" as res _col(42) %10.3f `sd_val'
        }
        
        * === EVALUATED PARAMETERS BLOCK ===
        local ptr_p = ""
        local ptr_d = ""
        local ptr_m = ""
        local ptr_n = ""
        
        if "`target'" == "power" local ptr_p "->"
        if "`target'" == "delta" local ptr_d "->"
        if "`target'" == "m"     local ptr_m "->"
        if "`target'" == "n"     local ptr_n "->"
        
        di as txt "{hline 54}"
        di as txt "  Evaluated Parameters:"
        di as txt _col(2) ""        _col(5) "Significance (α)"              _col(40) "=" as res _col(42) %10.3f `alpha'
        di as txt _col(2) "`ptr_p'" _col(5) "Statistical Power (1-β)"       _col(40) "=" as res _col(42) %10.3f `power'
        di ""
        di as txt _col(2) "`ptr_d'" _col(5) "Min Detectable Effect (δ)"     _col(40) "=" as res _col(42) %10.3f `delta'
        
        if `is_prop' == 0 & `sd_val' != 1 {
            local std_delta = `delta' / `sd_val'
            di as txt _col(2) ""    _col(5) "Standardized Effect (δ*)"      _col(40) "=" as res _col(42) %10.3f `std_delta'
        }
        di ""
        
        di as txt _col(2) "`ptr_m'" _col(5) "Treatment Clusters (m_t)"      _col(40) "=" as res _col(42) %10.0f `mt'
        di as txt _col(2) ""        _col(5) "Control Clusters (m_c)"        _col(40) "=" as res _col(42) %10.0f `mc'
        di as txt _col(2) "`ptr_n'" _col(5) "Cluster Size (n)"              _col(40) "=" as res _col(42) %10.0f ceil(`n')
        di as txt _col(2) ""        _col(5) "Total Observations (N)"        _col(40) "=" as res _col(42) %10.0fc `total_N'
        di as txt "{hline 54}"
        di as txt "  -> Evaluated target parameter"
        di ""
        
        return scalar m     = `m_ceil'
        return scalar mt    = `mt'
        return scalar mc    = `mc'
        return scalar n     = ceil(`n')
        return scalar delta = `delta'
        
        if `is_prop' == 0 & `sd_val' != 1 {
            return scalar delta_std = `delta' / `sd_val'
        }
        
        return scalar power = `power'
        return scalar N     = `total_N'
    }

	// =========================================================================
    // BRANCH B: RANGE EVALUATION & GRAPHING (Numlist Detected)
    // =========================================================================
    else {
        preserve
        drop _all
        
        local obs_count : word count `range_list'
        quietly set obs `obs_count'
        
        quietly gen `range_var'_x = .
        local row = 1
        foreach val of local range_list {
            quietly replace `range_var'_x = `val' in `row'
            local ++row
        }
        
        quietly gen `target'_y = .
        
        quietly {
            forval i = 1/`obs_count' {
                
                local x_val = `range_var'_x[`i']
                
                local m_loop "`m'"
                if "`range_var'" == "m" local m_loop "`x_val'"
                
                local n_loop "`n'"
                if "`range_var'" == "n" local n_loop "`x_val'"
                
                local power_loop "`power'"
                if "`range_var'" == "power" local power_loop "`x_val'"
                
                local delta_loop "`delta'"
                local sd_loop "`sd_val'"
                if "`range_var'" == "delta" {
                    if `is_prop' == 1 {
                        local delta_loop = abs(`x_val' - `p_anchor')
                        local pbar = (`x_val' + `p_anchor') / 2
                        local sd_loop = sqrt(`pbar' * (1 - `pbar'))
                    }
                    else {
                        local delta_loop = `x_val'
                    }
                }
                
                if "`target'" == "power" {
                    local z_b = `delta_loop' * sqrt((`p_alloc'*(1-`p_alloc')*`m_loop') / (`sd_loop'^2 * `theta' * (`rhoj'*`psi' + (1-`rhoj')/`n_loop'))) - `z_a'
                    replace `target'_y = normal(`z_b') in `i'
                }
                else if "`target'" == "delta" {
                    local z_b = invnormal(real("`power_loop'"))
                    replace `target'_y = (`z_a' + `z_b') * `sd_loop' * sqrt( (`theta') / (`p_alloc'*(1-`p_alloc')*`m_loop') * (`rhoj'*`psi' + (1-`rhoj')/`n_loop') ) in `i'
                }
                else if "`target'" == "m" {
                    local z_b = invnormal(real("`power_loop'"))
                    replace `target'_y = ((`z_a' + `z_b')^2 * `sd_loop'^2) / (`p_alloc'*(1-`p_alloc')*`delta_loop'^2) * `theta' * (`rhoj'*`psi' + (1-`rhoj')/`n_loop') in `i'
                }
                else if "`target'" == "n" {
                    local z_b = invnormal(real("`power_loop'"))
                    local denom = (`p_alloc'*(1-`p_alloc')*`m_loop'*`delta_loop'^2) / (`sd_loop'^2 * `theta' * (`z_a' + `z_b')^2) - `rhoj'*`psi'
                    if `denom' > 0 {
                        replace `target'_y = (1-`rhoj') / `denom' in `i'
                    }
                }
            }
        }
        
        * Set Clean Graph Titles (Using Stata Graph Text Tags)
        local y_title = proper("`target'")
        if "`target'" == "power" local y_title "Statistical Power"
        if "`target'" == "delta" local y_title "Minimum Detectable Effect ({it:{&delta}})"
        if "`target'" == "m"     local y_title "Total Clusters (m)"
        if "`target'" == "n"     local y_title "Cluster Size (n)"
        
        local x_title = proper("`range_var'")
        if "`range_var'" == "power" local x_title "Statistical Power"
        if "`range_var'" == "delta" local x_title "Minimum Detectable Effect ({it:{&delta}})"
        if "`range_var'" == "m"     local x_title "Total Clusters (m)"
        if "`range_var'" == "n"     local x_title "Cluster Size (n)"

        * Set Dynamic Parameter Setup String
        local setup_str "Parameter setup: T{sub:0}=`t0'; T{sub:1}=`t1'; {it:{&alpha}}=`alpha'"
        if "`target'" != "delta" & "`range_var'" != "delta" local setup_str "`setup_str'; {it:{&delta}}=`delta'"
        if "`target'" != "m" & "`range_var'" != "m"         local setup_str "`setup_str'; m=`m'"
        if "`target'" != "n" & "`range_var'" != "n"         local setup_str "`setup_str'; n=`n'"
        local setup_str "`setup_str'; {it:{&rho}}{sub:j}=`rhoj'; {it:{&rho}}{sub:t}=`rhot'"
        
        * Exact Mathematical Crosshair Logic (User-Defined or Smart Default)
        local crosshair ""
        local x_line_opt ""
        local y_line_opt ""
        
        local c_val ""
        if "`crossval'" != "" {
            local c_val = real("`crossval'")
        }
        else if "`target'" == "power" | "`range_var'" == "power" {
            local c_val = 0.80
        }
        
        if "`c_val'" != "" {
            local m_fixed = real("`m'")
            local n_fixed = real("`n'")
            local d_fixed "`delta'"
            local cross_x ""
            local cross_y ""
            
            * CASE 1: Benchmark value maps to the Y-Axis (The Target Parameter)
            if "`target'" == "power" {
                local z_b_cross = invnormal(`c_val')
                local cross_y = `c_val'
                
                if "`range_var'" == "m" {
                    local cross_x = ((`z_a' + `z_b_cross')^2 * `sd_val'^2) / (`p_alloc'*(1-`p_alloc')*`d_fixed'^2) * `theta' * (`rhoj'*`psi' + (1-`rhoj')/`n_fixed')
                }
                else if "`range_var'" == "n" {
                    local denom = (`p_alloc'*(1-`p_alloc')*`m_fixed'*`d_fixed'^2) / (`sd_val'^2 * `theta' * (`z_a' + `z_b_cross')^2) - `rhoj'*`psi'
                    local cross_x = (1-`rhoj') / `denom'
                }
                else if "`range_var'" == "delta" {
                    local cross_x = (`z_a' + `z_b_cross') * `sd_val' * sqrt( (`theta') / (`p_alloc'*(1-`p_alloc')*`m_fixed') * (`rhoj'*`psi' + (1-`rhoj')/`n_fixed') )
                }
            }
            
            * CASE 2: Benchmark value maps to the X-Axis (The Variable Parameter Range)
            else if "`range_var'" == "power" {
                local z_b_cross = invnormal(`c_val')
                local cross_x = `c_val'
                
                if "`target'" == "m" {
                    local cross_y = ((`z_a' + `z_b_cross')^2 * `sd_val'^2) / (`p_alloc'*(1-`p_alloc')*`d_fixed'^2) * `theta' * (`rhoj'*`psi' + (1-`rhoj')/`n_fixed')
                }
                else if "`range_var'" == "n" {
                    local denom = (`p_alloc'*(1-`p_alloc')*`m_fixed'*`d_fixed'^2) / (`sd_val'^2 * `theta' * (`z_a' + `z_b_cross')^2) - `rhoj'*`psi'
                    local cross_y = (1-`rhoj') / `denom'
                }
                else if "`range_var'" == "delta" {
                    local cross_y = (`z_a' + `z_b_cross') * `sd_val' * sqrt( (`theta') / (`p_alloc'*(1-`p_alloc')*`m_fixed') * (`rhoj'*`psi' + (1-`rhoj')/`n_fixed') )
                }
            }
            else if "`range_var'" == "m" & "`target'" != "power" {
                local cross_x = `c_val'
                local z_b_fixed = invnormal(real("`power'"))
                if "`target'" == "delta" {
                    local cross_y = (`z_a' + `z_b_fixed') * `sd_val' * sqrt( (`theta') / (`p_alloc'*(1-`p_alloc')*`cross_x') * (`rhoj'*`psi' + (1-`rhoj')/`n_fixed') )
                }
                else if "`target'" == "n" {
                    local denom = (`p_alloc'*(1-`p_alloc')*`cross_x'*`d_fixed'^2) / (`sd_val'^2 * `theta' * (`z_a' + `z_b_fixed')^2) - `rhoj'*`psi'
                    local cross_y = (1-`rhoj') / `denom'
                }
            }
            else if "`range_var'" == "n" & "`target'" != "power" {
                local cross_x = `c_val'
                local z_b_fixed = invnormal(real("`power'"))
                if "`target'" == "delta" {
                    local cross_y = (`z_a' + `z_b_fixed') * `sd_val' * sqrt( (`theta') / (`p_alloc'*(1-`p_alloc')*`m_fixed') * (`rhoj'*`psi' + (1-`rhoj')/`cross_x') )
                }
                else if "`target'" == "m" {
                    local cross_y = ((`z_a' + `z_b_fixed')^2 * `sd_val'^2) / (`p_alloc'*(1-`p_alloc')*`d_fixed'^2) * `theta' * (`rhoj'*`psi' + (1-`rhoj')/`cross_x')
                }
            }

            * Snap calculated intersection point onto the curve dataset
            if "`cross_x'" != "" & "`cross_y'" != "" {
                quietly sum `range_var'_x
                if `cross_x' >= r(min) & `cross_x' <= r(max) {
                    local new_obs = _N + 1
                    quietly set obs `new_obs'
                    quietly replace `range_var'_x = `cross_x' in `new_obs'
                    quietly replace `target'_y = `cross_y' in `new_obs'
                    sort `range_var'_x
                    
                    local crosshair = "(scatteri `cross_y' `cross_x', msymbol(O) mcolor(red) msize(medium))"
                    local x_line_opt = "xline(`cross_x', lpattern(dash) lcolor(gs10))"
                    local y_line_opt = "yline(`cross_y', lpattern(dash) lcolor(gs10))"
                }
            }
        }

        di as txt ""
        di as txt "--> Generating Multi-Period Frontier Graph for `y_title' vs `x_title'..."
        
        twoway (line `target'_y `range_var'_x, sort lcolor(navy) lwidth(medthick)) ///
               `crosshair', ///
               xtitle("`x_title'") ytitle("`y_title'") ///
               xlabel(#12, nogrid) ///
               ylabel(#8, nogrid) ///
               note("`setup_str'", color(gs6)) ///
               `x_line_opt' `y_line_opt' ///
               graphregion(color(white)) bgcolor(white) legend(off)

        restore
    }
end
