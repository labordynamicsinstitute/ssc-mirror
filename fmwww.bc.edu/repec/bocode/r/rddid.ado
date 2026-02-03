*! version 2.2.1  Jonathan Dries  01Feb2026
program define rddid, eclass
    version 14.0

    syntax varlist(min=2 max=2 numeric) [if] [in], ///
        Group(varname) ///
        [ h(numlist max=4) bw(string) Est(string) Bootstrap Reps(integer 50) ///
          c(real 0) Seed(integer -1) BWSelect(string) vce(string) * ]

    marksample touse
    markout `touse' `group'

    gettoken y x : varlist

    if "`bw'" == "" local bw "common"
    if "`est'" == "" local est "robust"

    if !inlist("`est'", "robust", "conventional", "biascorrected") {
        di as err "Option est() must be 'robust', 'conventional', or 'biascorrected'"
        exit 198
    }

    * --- Parse vce() ---
    * Extract cluster variable if vce(cluster varname) was specified
    local bs_cluster ""
    local vce_opt ""
    if `"`vce'"' != "" {
        local vce_opt `"vce(`vce')"'
        * Check if it's vce(cluster ...)
        gettoken vce_type vce_rest : vce
        if "`vce_type'" == "cluster" | "`vce_type'" == "cl" {
            local bs_cluster "`vce_rest'"
        }
    }

    * Build rdrobust options: passthrough options + cutoff + vce
    local rd_options `"`options' c(`c')"'
    if `"`vce_opt'"' != "" {
        local rd_options `"`rd_options' `vce_opt'"'
    }

    * Build bwselect option for rdbwselect calls
    local bwsel_opt ""
    if "`bwselect'" != "" {
        local bwsel_opt `"bwselect(`bwselect')"'
    }

    * --- Bandwidth Selection Logic ---
    local n_h : word count `h'

    if `n_h' > 0 {
        * MANUAL BANDWIDTHS
        tokenize `h'
        if `n_h' == 1 {
            local h_t "`1'"
            local h_c "`1'"
            di as txt "Using manual symmetric bandwidth: `1' (Common)"
        }
        else if `n_h' == 2 {
            local h_t "`1'"
            local h_c "`2'"
            di as txt "Using manual symmetric bandwidths: Treated=`1', Control=`2'"
        }
        else if `n_h' == 4 {
            local h_t "`1' `2'"
            local h_c "`3' `4'"
            di as txt "Using manual asymmetric bandwidths:"
            di as txt "  Treated: Left=`1', Right=`2'"
            di as txt "  Control: Left=`3', Right=`4'"
        }
        else {
            di as err "Option h() requires 1, 2, or 4 numbers."
            exit 198
        }
    }
    else {
        * AUTOMATIC OPTIMAL BANDWIDTHS
        di as txt "Calculating optimal bandwidths (`bw')..."

        quietly rdbwselect `y' `x' if `group'==1 & `touse', `rd_options' `bwsel_opt'
        local h_t = e(h_mserd)

        if "`bw'" == "common" {
            local h_c = `h_t'
        }
        else if "`bw'" == "independent" {
            quietly rdbwselect `y' `x' if `group'==0 & `touse', `rd_options' `bwsel_opt'
            local h_c = e(h_mserd)
        }
        else {
            di as err "Option bw() must be 'common' or 'independent'"
            exit 198
        }
    }

    * --- Estimation ---
    if "`bootstrap'" != "" {

        if "`bs_cluster'" != "" {
            di as txt "Cluster bootstrap on: `bs_cluster'"
        }
        di as txt "Bootstrapping `reps' replications..."

        if `seed' != -1 {
            set seed `seed'
        }

        * --- Original-sample point estimate ---
        quietly rdrobust `y' `x' if `group' == 1 & `touse', h(`h_t') `rd_options'
        local N_t = e(N)
        if "`est'" == "conventional" {
            local b_t_orig = e(tau_cl)
        }
        else {
            local b_t_orig = e(tau_bc)
        }

        quietly rdrobust `y' `x' if `group' == 0 & `touse', h(`h_c') `rd_options'
        local N_c = e(N)
        if "`est'" == "conventional" {
            local b_c_orig = e(tau_cl)
        }
        else {
            local b_c_orig = e(tau_bc)
        }

        local diff_orig = `b_t_orig' - `b_c_orig'

        * --- Manual bootstrap loop ---
        tempname bs_results
        matrix `bs_results' = J(`reps', 1, .)
        local bs_good = 0

        forvalues i = 1/`reps' {
            preserve
            quietly keep if `touse'

            if "`bs_cluster'" != "" {
                bsample, cluster(`bs_cluster')
            }
            else {
                bsample
            }

            * Treated RD on resampled data
            capture rdrobust `y' `x' if `group' == 1, h(`h_t') `rd_options'
            if _rc == 0 {
                if "`est'" == "conventional" {
                    local b_t_bs = e(tau_cl)
                }
                else {
                    local b_t_bs = e(tau_bc)
                }

                * Control RD on resampled data
                capture rdrobust `y' `x' if `group' == 0, h(`h_c') `rd_options'
                if _rc == 0 {
                    if "`est'" == "conventional" {
                        local b_c_bs = e(tau_cl)
                    }
                    else {
                        local b_c_bs = e(tau_bc)
                    }

                    matrix `bs_results'[`i', 1] = `b_t_bs' - `b_c_bs'
                    local bs_good = `bs_good' + 1
                }
            }

            restore

            * Progress dots
            if mod(`i', 50) == 0 {
                di as txt "." _continue
            }
        }
        di ""

        if `bs_good' < 3 {
            di as err "Bootstrap failed: only `bs_good' of `reps' replications succeeded."
            exit 2000
        }

        if `bs_good' < `reps' {
            di as txt "Note: `bs_good' of `reps' replications succeeded."
        }

        * Compute bootstrap SE using mata
        mata: st_local("bs_se", strofreal(sqrt(variance( ///
            select(st_matrix("`bs_results'"), st_matrix("`bs_results'") :< .)))))

        local bs_se = real("`bs_se'")
        local bs_z = `diff_orig' / `bs_se'
        local bs_p = 2 * (1 - normal(abs(`bs_z')))

        * --- Display ---
        di _n as txt "Diff-in-Disc Results (Bootstrap, `est')"
        di as txt "{hline 56}"
        di as txt %18s "" as txt "    Coef.   Std. Err.      z    P>|z|"
        di as txt "{hline 56}"
        di as txt %18s "{bf:DiDC}" "  " as res %9.4f `diff_orig' "  " %9.4f `bs_se' ///
           "  " %6.2f `bs_z' "  " %6.4f `bs_p'
        di as txt "{hline 56}"
        di as txt "Estimation type:         " as res "`est'"
        if "`bs_cluster'" != "" {
            di as txt "Bootstrap clustering:     " as res "`bs_cluster'"
        }
        di as txt "Bootstrap replications:  " as res "`bs_good' / `reps'"
        di as txt "Treated Bandwidth (L/R): " as res "`h_t'"
        di as txt "Control Bandwidth (L/R): " as res "`h_c'"
        di as txt "N (Treated / Control):   " as res "`N_t' / `N_c'"

        * --- Post results ---
        tempname b V
        matrix `b' = (`diff_orig')
        matrix `V' = (`bs_se'^2)
        matrix colnames `b' = diff
        matrix colnames `V' = diff
        matrix rownames `V' = diff

        ereturn post `b' `V', esample(`touse')

        ereturn scalar N = `N_t' + `N_c'
        ereturn scalar N_t = `N_t'
        ereturn scalar N_c = `N_c'
        ereturn scalar tau_t = `b_t_orig'
        ereturn scalar tau_c = `b_c_orig'
        ereturn scalar bs_reps = `reps'
        ereturn scalar bs_good = `bs_good'
        ereturn matrix bs_dist = `bs_results'
        ereturn local bw_type "`bw'"
        ereturn local vce "bootstrap"
        ereturn local estimation "`est'"

        rddid_post_bw, ht(`h_t') hc(`h_c')

        ereturn local depvar "`y'"
        ereturn local runvar "`x'"
        ereturn local group "`group'"
        ereturn scalar cutoff = `c'
        ereturn local cmd "rddid"
    }
    else {
        * --- Analytic SEs ---
        quietly rdrobust `y' `x' if `group' == 1 & `touse', h(`h_t') `rd_options'
        local N_t = e(N)
        if "`est'" == "conventional" {
            local b_t = e(tau_cl)
            local se_t = e(se_tau_cl)
        }
        else if "`est'" == "biascorrected" {
            local b_t = e(tau_bc)
            local se_t = e(se_tau_cl)
        }
        else {
            local b_t = e(tau_bc)
            local se_t = e(se_tau_rb)
        }

        quietly rdrobust `y' `x' if `group' == 0 & `touse', h(`h_c') `rd_options'
        local N_c = e(N)
        if "`est'" == "conventional" {
            local b_c = e(tau_cl)
            local se_c = e(se_tau_cl)
        }
        else if "`est'" == "biascorrected" {
            local b_c = e(tau_bc)
            local se_c = e(se_tau_cl)
        }
        else {
            local b_c = e(tau_bc)
            local se_c = e(se_tau_rb)
        }

        local diff = `b_t' - `b_c'
        local se_diff = sqrt(`se_t'^2 + `se_c'^2)
        local z = `diff' / `se_diff'
        local p = 2 * (1 - normal(abs(`z')))

        local z_t = `b_t' / `se_t'
        local p_t = 2 * (1 - normal(abs(`z_t')))
        local z_c = `b_c' / `se_c'
        local p_c = 2 * (1 - normal(abs(`z_c')))

        * --- Display Results Table ---
        di _n as txt "Diff-in-Disc Results (`est')"
        di as txt "{hline 56}"
        di as txt %18s "" as txt "    Coef.   Std. Err.      z    P>|z|"
        di as txt "{hline 56}"
        di as txt %18s "Treated RD" "  " as res %9.4f `b_t' "  " %9.4f `se_t' ///
           "  " %6.2f `z_t' "  " %6.4f `p_t'
        di as txt %18s "Control RD" "  " as res %9.4f `b_c' "  " %9.4f `se_c' ///
           "  " %6.2f `z_c' "  " %6.4f `p_c'
        di as txt "{hline 56}"
        di as txt %18s "{bf:DiDC}" "  " as res %9.4f `diff' "  " %9.4f `se_diff' ///
           "  " %6.2f `z' "  " %6.4f `p'
        di as txt "{hline 56}"
        di as txt "Treated Bandwidth (L/R): " as res "`h_t'"
        di as txt "Control Bandwidth (L/R): " as res "`h_c'"
        di as txt "N (Treated / Control):   " as res "`N_t' / `N_c'"

        tempname b V
        matrix `b' = (`diff')
        matrix `V' = (`se_diff'^2)
        matrix colnames `b' = diff
        matrix colnames `V' = diff
        matrix rownames `V' = diff

        ereturn post `b' `V', esample(`touse')

        rddid_post_bw, ht(`h_t') hc(`h_c')

        ereturn scalar N = `N_t' + `N_c'
        ereturn scalar N_t = `N_t'
        ereturn scalar N_c = `N_c'
        ereturn scalar tau_t = `b_t'
        ereturn scalar se_t = `se_t'
        ereturn scalar tau_c = `b_c'
        ereturn scalar se_c = `se_c'
        ereturn local bw_type "`bw'"
        ereturn local vce "analytic"
        ereturn local estimation "`est'"
        ereturn local depvar "`y'"
        ereturn local runvar "`x'"
        ereturn local group "`group'"
        ereturn scalar cutoff = `c'
        ereturn local cmd "rddid"
    }
end
