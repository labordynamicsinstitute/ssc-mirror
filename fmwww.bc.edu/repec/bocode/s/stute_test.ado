cap program drop stute_test
program define stute_test, rclass
syntax varlist(max = 4 min = 2) [if] [in] [, order(integer 1) seed(string) brep(integer 500) baseline(string)] 
version 12.0
marksample touse_main
qui {
    preserve
    keep if `touse_main' // Outer sample selection

    tokenize `varlist'

    // Setup seed and bootstrap reps
    if "`seed'" != "" set seed `seed'
    if missing(`order') scalar k = 1
    else scalar k = `order'
    scalar breps = `brep'

    // Pre-allocate the result matrix, the sum of the test statistics and the sum of the bootstrapped test stat
    mata: res_mat = J(1, 3, .)
    mata: t_tot = 0
    mata: t_boot = J(st_numscalar("breps"), 1, 0)

    if "`3'" == "" & "`4'" == "" {
        // Cross section mode - Only Y and X
        // We use the full sample to compute the test statistic

        if "`baseline'" != "" {
            di as err "G and T arguments required when the baseline option is requested."
            exit
        }

        // Pre-allocate the V matrix for the wild bootstrap
        scalar GG = _N
        mata: st_numscalar("breps")
        mata: V = uniform(st_numscalar("GG"), st_numscalar("breps"))
        scalar drop GG

        // Run inner routine
        _stute `1' `2'
    }
    else if "`3'" != "" & "`4'" != "" {
        // Panel mode - G and T required
        // The test statistics are computed for each value of T (the inner program is byable)
        // If there is a baseline period specified in the option, the new Y and D are the long differences of the outcome and treatment wrt to the baseline period and the command is run in panel mode.

        // A balanced panel is required
        xtset `3' `4'
        if r(balanced) != "strongly balanced" {
            di as err "Balanced panel required in panel mode."
            exit
        }

        // Pre-allocate the V matrix for the wild bootstrap
        egen G_ids = group(`3')
        sum G_ids
        scalar GG = r(max)
        drop G_ids        
        mata: V = uniform(st_numscalar("GG"), st_numscalar("breps"))
        scalar drop GG

        if "`baseline'" != "" {
            // Running the inner program with by and long differences
            qui count if `4' == `baseline'
            if r(N) == 0 {
                di as err "Baseline period not found in the support of the T variable."
                exit
            }

            foreach v of varlist `1' `2' {
                gen b`v'_temp = `v' if `4' == `baseline'
                bys `3': egen b`v' = mean(b`v'_temp)
                gen `v'_b = `v'- b`v' 
            }
            drop if `4' == `baseline'
            bys `4': _stute `1'_b `2'_b `3' `4'
            cap drop bY_temp bY Y_b bX_temp bX X_b
        }
        else {
            // Running the inner program with by
            bys `4': _stute `1' `2' `3' `4'
        }

        // The results in the panel mode are gathered via a recursive append which takes place in the stute() mata function.
        // At the same time, the test stats and their bootstrap are added together in the same recursive way.
        // With the function below, we obtain the p-value for the joint test statistic.        
        mata: aggte(t_tot, t_boot)
        mat coln aggte_out = "t stat" "p-value"
    }
    else {
        // The exit code is "invalid syntax".
        exit 197
    }

    mata: st_matrix("M", res_mat[2..rows(res_mat), ])
    mata: st_numscalar("periods", rows(res_mat) - 1)
    mat coln M = "t" "t stat" "p-value"
}       
    di as result ""
    if M[1,1] == . {
        di as result "(Cramer-von Mises) Cross Sectional Stute Test"
        matlist M[1, 2..3], names(columns)  
    }
    else {
        local rown ""
        forv c = 1/`=periods' {
            if "`baseline'" != "" {
                local rown "`rown' `:di M[`c', 1] - `baseline''"
            }
            else {
                local rown "`rown' `:di M[`c', 1]'"
            }
        }
        mat rown M = `rown'

        di as result "(Cramer-von Mises) Panel Stute Test"
        if "`baseline'" != "" di as result "Baseline: `baseline'"
        matlist M[1..., 2..3]
        di as result ""
        di as result "Joint Stute test: `=strtrim("`: di %9.4fc aggte_out[1,1]'")' (`=strtrim("`:di %9.4fc aggte_out[1,2]'")')" 
        di as text "p-value in parenthesis."
        return matrix joint = aggte_out
    }
    restore
    return matrix main = M

    mata: mata drop V data res_mat t_boot t_tot
end

// This program calls the mata function on the "right" portion of the data, i.e. on the full sample in cross section mode, by time periods in panel mode.
cap program drop _stute
program define _stute, rclass byable(recall, noheader) sortpreserve 
syntax varlist(max = 4 min = 2) [if] [in] 
marksample touse
qui {
    if _by() {
        qui replace `touse' = 0 if `_byindex' != _byindex()
        sum `4' if `touse' == 1
        scalar by_scalar = r(mean)
    }
    mata: data = select(st_data(., ("`1'", "`2'")), st_data(., "`touse'") :== 1)
    mata: stute(data, st_numscalar("k"), st_numscalar("breps"), res_mat, V, t_tot, t_boot)
    if _by() {
        mata: res_mat[rows(res_mat), 1] = st_numscalar("by_scalar")
        scalar drop by_scalar
    }
}
end

// The function below is the workhorse function of the program, in that it computes the test statistics and their p-values
cap mata: mata drop stute()
mata:
    void stute(data, k, brep, res_mat, V, t_tot, t_boot) {
        data = sort(data, (2, 1)) 
        // Sorting by Y within sorting by D is required since, otherwise, if many units have the same D, the program will return different results with the same data.

        Y = data[,1]
        D = data[,2]
        N = rows(Y)
        X = J(rows(D), (k+1), .)
        for (j = 0; j <= k; j++) {
            X[,j+1] = D:^j
        }
        b = invsym(X'X) * X'Y
        e_lin = Y - X * b
        mat_e_lin = e_lin * e_lin'

        mat_temp = (1..N)'
        for (j = 1; j <= N-1; j++) {
            mat_temp = mat_temp, (J(j,1, j+1)\((j+1)..N)')
        }
        mat_temp = (J(N,N,(N+1)/N) - mat_temp)/N

        out_mat = J(1, 3, .)
        out_mat[1,2] = sum(mat_e_lin :* mat_temp)/N

        c1 = (sqrt(5) + 1)/(2+sqrt(5))
        c2 = (1 - sqrt(5))/2
        c3 = sqrt(5)
        bres = J(brep, 1, .)
        F = V, D
        F = sort(F, cols(F))
        for (i = 1; i <= brep; i++) {
            Y_st = X * b + (J(N,1,c2) + c3*(floor(F[,i] :> J(N, 1, c1)))) :* e_lin
            b_st = invsym(X'X) * X' Y_st
            e_lin_st = Y_st - X * b_st
            mat_e_lin_st = e_lin_st * e_lin_st'
            bres[i, 1] = sum(mat_e_lin_st :* mat_temp)/N
        }
        out_mat[1,3] = mean(bres :> J(brep, 1, out_mat[1,2]))

        // The final results are first included as arguments, then recursively appended/summed and exported to the environment.
        res_mat = res_mat \ out_mat
        t_tot = t_tot + out_mat[1, 2]
        t_boot = t_boot + bres

        st_matrix("res_mat", res_mat)
        st_numscalar("t_tot", t_tot)
        st_matrix("t_boot", t_boot)
    }
end

// This function computes the p-value for the joint test statistic.
cap mata: mata drop aggte()
mata:
void aggte(t, B) {
    aggte_out = J(1, 2, .)
    aggte_out[1,1] = t
    aggte_out[1,2] = mean(B :> J(rows(B), 1, t))
    st_matrix("aggte_out", aggte_out)
}
end