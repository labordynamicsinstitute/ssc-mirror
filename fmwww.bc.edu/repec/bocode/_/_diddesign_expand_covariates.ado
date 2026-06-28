*! _diddesign_expand_covariates.ado - Expand covariates with factor support
*!
*! Internal helper used by diddesign, diddesign_check, and _diddesign_sa.
*! Factor-variable terms are expanded via fvrevar and base/constant columns
*! are excluded so that the downstream design matrix does not contain
*! spurious zero or constant columns.

version 16.0

program define _diddesign_expand_covariates, rclass
    version 16.0

    syntax , COVARS(string asis) TOUSE(name)

    local covars_str = trim("`covars'")
    if "`covars_str'" == "" {
        return local varlist ""
        return local generated_vars ""
        return local encoded_sources ""
        return scalar n_factor_expanded = 0
        return scalar n_constant_dropped = 0
        exit
    }

    local prepared_covars ""
    local has_fvops "`r(fvops)'"

    local expanded_vars ""
    local generated_vars ""
    local n_fv_expanded = 0
    local n_constant_dropped = 0
    local generated_counter = 0
    local encoded_sources ""
    local encoded_targets ""

    foreach covar_term of local covars_str {
        local token_stream = subinstr("`covar_term'", "##", " __diddesign_dhash__ ", .)
        local token_stream = subinstr("`token_stream'", "#", " # ", .)
        local token_stream = subinstr("`token_stream'", "__diddesign_dhash__", " # # ", .)
        local rebuilt_term ""

        foreach token of local token_stream {
            if "`token'" == "#" {
                local rebuilt_term "`rebuilt_term'#"
            }
            else {
                local token_prefix ""
                local token_var "`token'"
                local dot_pos = strpos("`token'", ".")
                local token_use "`token'"

                if `dot_pos' > 0 {
                    local token_prefix = substr("`token'", 1, `dot_pos')
                    local token_var = substr("`token'", `dot_pos' + 1, .)
                }

                capture confirm string variable `token_var'
                if _rc == 0 {
                    local token_prefix_lower = lower("`token_prefix'")
                    local is_factor_token = regexm("`token_prefix_lower'", "^i(bn?|b?[0-9]*)?\.$")

                    if !`is_factor_token' {
                        display as error "E017: String covariate `token_var' must use factor-variable notation"
                        exit 109
                    }

                    local source_pos : list posof "`token_var'" in encoded_sources
                    if `source_pos' > 0 {
                        local token_target : word `source_pos' of `encoded_targets'
                    }
                    else {
                        local ++generated_counter
                        local token_target "__diddesign_sfv_`generated_counter'"
                        capture confirm new variable `token_target'
                        while _rc != 0 {
                            local ++generated_counter
                            local token_target "__diddesign_sfv_`generated_counter'"
                            capture confirm new variable `token_target'
                        }
                        quietly encode `token_var' if `touse', gen(`token_target')
                        local generated_vars "`generated_vars' `token_target'"
                        local encoded_sources "`encoded_sources' `token_var'"
                        local encoded_targets "`encoded_targets' `token_target'"
                    }

                    local token_use "`token_prefix'`token_target'"
                }

                local rebuilt_term "`rebuilt_term'`token_use'"
            }
        }

        local prepared_covars "`prepared_covars' `rebuilt_term'"
    }

    local prepared_covars : list retokenize prepared_covars

    fvexpand `prepared_covars' if `touse'
    local has_fvops "`r(fvops)'"

    if "`has_fvops'" == "true" {
        foreach covar_term of local prepared_covars {
            local is_factor = 0
            if regexm("`covar_term'", "^i\.") | regexm("`covar_term'", "^i\(") {
                local is_factor = 1
            }
            if regexm("`covar_term'", "^ibn\.") | regexm("`covar_term'", "^ib[0-9]+") {
                local is_factor = 1
            }
            if regexm("`covar_term'", "^c\.") {
                local is_factor = 0
            }

            if `is_factor' {
                fvrevar `covar_term' if `touse'
                local fv_vars "`r(varlist)'"
                local n_fv : word count `fv_vars'
                local kept_vars ""
                local dropped_any_constant = 0

                foreach v of local fv_vars {
                    quietly summarize `v' if `touse', meanonly
                    if r(N) == 0 {
                        continue
                    }
                    if r(min) == r(max) {
                        local dropped_any_constant = 1
                        local n_constant_dropped = `n_constant_dropped' + 1
                    }
                    else {
                        local kept_vars "`kept_vars' `v'"
                    }
                }

                if "`kept_vars'" != "" {
                    local n_kept : word count `kept_vars'
                    local persistent_vars ""
                    foreach v of local kept_vars {
                        local use_var "`v'"
                        if substr("`v'", 1, 2) == "__" {
                            local ++generated_counter
                            local use_var "__diddesign_fv_`generated_counter'"
                            capture confirm new variable `use_var'
                            while _rc != 0 {
                                local ++generated_counter
                                local use_var "__diddesign_fv_`generated_counter'"
                                capture confirm new variable `use_var'
                            }
                            quietly gen double `use_var' = `v'
                            local generated_vars "`generated_vars' `use_var'"
                        }
                        local persistent_vars "`persistent_vars' `use_var'"
                    }
                    local expanded_vars "`expanded_vars' `persistent_vars'"
                    local n_fv_expanded = `n_fv_expanded' + `n_kept'
                }
            }
            else {
                capture fvrevar `covar_term' if `touse'
                if _rc == 0 {
                    local resolved_vars "`r(varlist)'"
                    local persistent_vars ""
                    foreach v of local resolved_vars {
                        local use_var "`v'"
                        if substr("`v'", 1, 2) == "__" {
                            local ++generated_counter
                            local use_var "__diddesign_fv_`generated_counter'"
                            capture confirm new variable `use_var'
                            while _rc != 0 {
                                local ++generated_counter
                                local use_var "__diddesign_fv_`generated_counter'"
                                capture confirm new variable `use_var'
                            }
                            quietly gen double `use_var' = `v'
                            local generated_vars "`generated_vars' `use_var'"
                        }
                        local persistent_vars "`persistent_vars' `use_var'"
                    }
                    local expanded_vars "`expanded_vars' `persistent_vars'"
                }
                else {
                    local expanded_vars "`expanded_vars' `covar_term'"
                }
            }
        }
    }
    else {
        foreach covar_term of local prepared_covars {
            capture fvrevar `covar_term' if `touse'
            if _rc == 0 {
                local resolved_vars "`r(varlist)'"
                local persistent_vars ""
                foreach v of local resolved_vars {
                    local use_var "`v'"
                    if substr("`v'", 1, 2) == "__" {
                        local ++generated_counter
                        local use_var "__diddesign_fv_`generated_counter'"
                        capture confirm new variable `use_var'
                        while _rc != 0 {
                            local ++generated_counter
                            local use_var "__diddesign_fv_`generated_counter'"
                            capture confirm new variable `use_var'
                        }
                        quietly gen double `use_var' = `v'
                        local generated_vars "`generated_vars' `use_var'"
                    }
                    local persistent_vars "`persistent_vars' `use_var'"
                }
                local expanded_vars "`expanded_vars' `persistent_vars'"
            }
            else {
                local expanded_vars "`expanded_vars' `covar_term'"
            }
        }
    }

    local expanded_vars : list retokenize expanded_vars
    local generated_vars : list retokenize generated_vars
    local encoded_sources : list retokenize encoded_sources

    return local varlist "`expanded_vars'"
    return local generated_vars "`generated_vars'"
    return local encoded_sources "`encoded_sources'"
    return scalar n_factor_expanded = `n_fv_expanded'
    return scalar n_constant_dropped = `n_constant_dropped'
end
