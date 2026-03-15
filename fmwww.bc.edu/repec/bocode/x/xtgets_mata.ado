*! xtgets_mata: Mata helper functions for panel GETS indicator saturation
*! Version 1.0.0  14mar2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! Implements: IIS, FESIS, CSIS, CFESIS, TIS, JIIS, JSIS indicator generation
*! Based on Pretis & Schwarz (2022/2026) "Discovering What Mattered"
*! R package: getspanel (Schwarz & Pretis, 2026, CRAN)
*! Original time-series gets.ado by Damian C. Clarke (2013)
*!
*! The indicator generation follows the R package exactly:
*!   - FESIS uses block-diagonal step matrices (gets::sim + Matrix::bdiag)
*!   - CSIS uses step x regressor interactions
*!   - CFESIS uses block-diagonal step x regressor interactions per unit
*!   - TIS uses block-diagonal trend matrices (gets::tim + Matrix::bdiag)
*!   - IIS, JIIS, JSIS use gets::iim / gets::sim directly
*!
*! The GETS selection follows Clarke (2013) gets.ado:
*!   - tsort() Mata function for t-statistic sorting
*!   - Multiple search paths (numsearch)
*!   - Misspecification tests at each elimination step

********************************************************************************
*** Mata functions for xtgets
********************************************************************************

cap mata: mata drop xtgets_sim()
cap mata: mata drop xtgets_iim()
cap mata: mata drop xtgets_tim()
cap mata: mata drop xtgets_gen_fesis()
cap mata: mata drop xtgets_gen_csis()
cap mata: mata drop xtgets_gen_cfesis()
cap mata: mata drop xtgets_gen_tis()
cap mata: mata drop xtgets_gen_iis()
cap mata: mata drop xtgets_gen_jiis()
cap mata: mata drop xtgets_gen_jsis()
cap mata: mata drop tsort()

mata:

// ============================================================================
// xtgets_sim: Generate Step Indicator Matrix for T periods
// Replicates R gets::sim(T)
// Creates a T x (T-1) matrix of step indicators
// Column j = step starting at period j+1 (1 from period j+1 onward, 0 before)
// ============================================================================
real matrix xtgets_sim(real scalar T)
{
    real matrix S
    real scalar j
    
    S = J(T, T-1, 0)
    for (j = 1; j <= T-1; j++) {
        S[|j+1, j \ T, j|] = J(T-j, 1, 1)
    }
    return(S)
}

// ============================================================================
// xtgets_iim: Generate Impulse Indicator Matrix for T periods
// Replicates R gets::iim(T)
// Creates a T x T identity matrix
// ============================================================================
real matrix xtgets_iim(real scalar T)
{
    return(I(T))
}

// ============================================================================
// xtgets_tim: Generate Trend Indicator Matrix for T periods
// Replicates R gets::tim(T)
// Creates a T x (T-1) matrix of broken trend indicators
// Column j = trend starting at period j+1: 0,0,...,0,1,2,...,T-j
// ============================================================================
real matrix xtgets_tim(real scalar T)
{
    real matrix TI
    real scalar j, k
    
    TI = J(T, T-1, 0)
    for (j = 1; j <= T-1; j++) {
        for (k = j+1; k <= T; k++) {
            TI[k, j] = k - j
        }
    }
    return(TI)
}

// ============================================================================
// xtgets_gen_fesis: Fixed-Effect Step Indicator Saturation
// Replicates R isatpanel fesis logic exactly:
//   1. Create gets::sim(T) for each unit
//   2. Block-diagonal via Matrix::bdiag
//   3. Name: fesis{id}.{time}
// ============================================================================
void xtgets_gen_fesis(string scalar idvar, string scalar tvar,
                       string scalar prefix, string scalar touse)
{
    real colvector id, time
    real matrix id_vals, time_vals
    real scalar N, T, n, i, j, k, col_idx
    string scalar vname
    real matrix sim_mat, indicator
    
    st_view(id, ., idvar, touse)
    st_view(time, ., tvar, touse)
    n = rows(id)
    
    id_vals = uniqrows(id)
    time_vals = uniqrows(time)
    N = rows(id_vals)
    T = rows(time_vals)
    
    // Generate sim(T) — same for each unit
    sim_mat = xtgets_sim(T)
    
    k = 0
    for (i = 1; i <= N; i++) {
        for (j = 1; j <= T-1; j++) {
            // Create indicator: 1 for unit i from time_vals[j+1] onward
            indicator = J(n, 1, 0)
            col_idx = 1
            for (col_idx = 1; col_idx <= n; col_idx++) {
                if (id[col_idx] == id_vals[i]) {
                    // Find position of this obs within unit's time series
                    real scalar t_pos
                    t_pos = 0
                    real scalar tt
                    for (tt = 1; tt <= T; tt++) {
                        if (time_vals[tt] == time[col_idx]) {
                            t_pos = tt
                            break
                        }
                    }
                    if (t_pos > 0) {
                        indicator[col_idx] = sim_mat[t_pos, j]
                    }
                }
            }
            
            // Only add if not all zeros
            if (sum(indicator) > 0) {
                vname = prefix + strofreal(id_vals[i]) + "_" + strofreal(time_vals[j+1])
                (void) st_addvar("byte", vname)
                st_store(., vname, touse, indicator)
                k++
            }
        }
    }
    printf("{txt}  FESIS: generated %g step indicators (%g units x %g periods)\n",
           k, N, T-1)
}

// ============================================================================
// xtgets_gen_jsis: Joint Step Indicator Saturation
// Common step indicators across all units: gets::sim(T)
// ============================================================================
void xtgets_gen_jsis(string scalar idvar, string scalar tvar,
                      string scalar prefix, string scalar touse)
{
    real colvector id, time
    real matrix time_vals
    real scalar T, n, j, t, k
    string scalar vname
    real colvector indicator
    real matrix sim_mat
    
    st_view(id, ., idvar, touse)
    st_view(time, ., tvar, touse)
    n = rows(id)
    
    time_vals = uniqrows(time)
    T = rows(time_vals)
    
    sim_mat = xtgets_sim(T)
    
    k = 0
    for (j = 1; j <= T-1; j++) {
        indicator = J(n, 1, 0)
        for (t = 1; t <= n; t++) {
            real scalar t_pos2
            t_pos2 = 0
            real scalar tt2
            for (tt2 = 1; tt2 <= T; tt2++) {
                if (time_vals[tt2] == time[t]) {
                    t_pos2 = tt2
                    break
                }
            }
            if (t_pos2 > 0) {
                indicator[t] = sim_mat[t_pos2, j]
            }
        }
        if (sum(indicator) > 0) {
            vname = prefix + strofreal(time_vals[j+1])
            (void) st_addvar("byte", vname)
            st_store(., vname, touse, indicator)
            k++
        }
    }
    printf("{txt}  JSIS: generated %g joint step indicators\n", k)
}

// ============================================================================
// xtgets_gen_jiis: Joint Impulse Indicator Saturation
// Common impulse indicators: gets::iim(T) — one per time period
// ============================================================================
void xtgets_gen_jiis(string scalar idvar, string scalar tvar,
                      string scalar prefix, string scalar touse)
{
    real colvector id, time
    real matrix time_vals
    real scalar T, n, j, t, k
    string scalar vname
    real colvector indicator
    
    st_view(id, ., idvar, touse)
    st_view(time, ., tvar, touse)
    n = rows(id)
    
    time_vals = uniqrows(time)
    T = rows(time_vals)
    
    k = 0
    for (j = 1; j <= T; j++) {
        indicator = J(n, 1, 0)
        for (t = 1; t <= n; t++) {
            if (time[t] == time_vals[j]) {
                indicator[t] = 1
            }
        }
        vname = prefix + strofreal(time_vals[j])
        (void) st_addvar("byte", vname)
        st_store(., vname, touse, indicator)
        k++
    }
    printf("{txt}  JIIS: generated %g joint impulse indicators\n", k)
}

// ============================================================================
// xtgets_gen_iis: Impulse Indicator Saturation
// Block-diagonal identity: gets::iim(T) per unit
// ============================================================================
void xtgets_gen_iis(string scalar idvar, string scalar tvar,
                     string scalar prefix, string scalar touse)
{
    real colvector id, time
    real matrix id_vals, time_vals
    real scalar N, T, n, i, j, k, col_idx
    string scalar vname
    real colvector indicator
    
    st_view(id, ., idvar, touse)
    st_view(time, ., tvar, touse)
    n = rows(id)
    
    id_vals = uniqrows(id)
    time_vals = uniqrows(time)
    N = rows(id_vals)
    T = rows(time_vals)
    
    k = 0
    for (i = 1; i <= N; i++) {
        for (j = 1; j <= T; j++) {
            indicator = J(n, 1, 0)
            for (col_idx = 1; col_idx <= n; col_idx++) {
                if (id[col_idx] == id_vals[i] & time[col_idx] == time_vals[j]) {
                    indicator[col_idx] = 1
                }
            }
            if (sum(indicator) > 0) {
                vname = prefix + strofreal(id_vals[i]) + "_" + strofreal(time_vals[j])
                (void) st_addvar("byte", vname)
                st_store(., vname, touse, indicator)
                k++
            }
        }
    }
    printf("{txt}  IIS: generated %g impulse indicators (%g units x %g periods)\n",
           k, N, T)
}

// ============================================================================
// xtgets_gen_csis: Coefficient Step Indicator Saturation
// Common step x regressor interactions: gets::sim(T) * each X_k
// Replicates R isatpanel csis logic
// ============================================================================
void xtgets_gen_csis(string scalar idvar, string scalar tvar,
                      string scalar xvars, string scalar prefix,
                      string scalar touse)
{
    real colvector id, time
    real matrix X, time_vals
    real scalar T, K, n, j, kk, t, cnt
    string scalar vname
    real colvector indicator
    string rowvector xnames
    real matrix sim_mat
    
    st_view(id, ., idvar, touse)
    st_view(time, ., tvar, touse)
    n = rows(id)
    
    xnames = tokens(xvars)
    K = cols(xnames)
    st_view(X, ., xnames, touse)
    
    time_vals = uniqrows(time)
    T = rows(time_vals)
    
    sim_mat = xtgets_sim(T)
    
    cnt = 0
    for (kk = 1; kk <= K; kk++) {
        for (j = 1; j <= T-1; j++) {
            // Create step indicator x regressor
            indicator = J(n, 1, 0)
            for (t = 1; t <= n; t++) {
                real scalar t_pos3
                t_pos3 = 0
                real scalar tt3
                for (tt3 = 1; tt3 <= T; tt3++) {
                    if (time_vals[tt3] == time[t]) {
                        t_pos3 = tt3
                        break
                    }
                }
                if (t_pos3 > 0) {
                    indicator[t] = sim_mat[t_pos3, j] * X[t, kk]
                }
            }
            
            if (sum(abs(indicator)) > 0) {
                vname = prefix + xnames[kk] + "_" + strofreal(time_vals[j+1])
                (void) st_addvar("double", vname)
                st_store(., vname, touse, indicator)
                cnt++
            }
        }
    }
    printf("{txt}  CSIS: generated %g indicators (%g vars x %g periods)\n",
           cnt, K, T-1)
}

// ============================================================================
// xtgets_gen_cfesis: Coefficient-FE Step Indicator Saturation
// Block-diagonal step x regressor interactions per unit
// Replicates R isatpanel cfesis logic
// ============================================================================
void xtgets_gen_cfesis(string scalar idvar, string scalar tvar,
                        string scalar xvars, string scalar prefix,
                        string scalar touse)
{
    real colvector id, time
    real matrix X, id_vals, time_vals
    real scalar N, T, K, n, i, j, kk, t, cnt
    string scalar vname
    real colvector indicator
    string rowvector xnames
    real matrix sim_mat
    
    st_view(id, ., idvar, touse)
    st_view(time, ., tvar, touse)
    n = rows(id)
    
    xnames = tokens(xvars)
    K = cols(xnames)
    st_view(X, ., xnames, touse)
    
    id_vals = uniqrows(id)
    time_vals = uniqrows(time)
    N = rows(id_vals)
    T = rows(time_vals)
    
    sim_mat = xtgets_sim(T)
    
    cnt = 0
    for (kk = 1; kk <= K; kk++) {
        for (i = 1; i <= N; i++) {
            for (j = 1; j <= T-1; j++) {
                indicator = J(n, 1, 0)
                for (t = 1; t <= n; t++) {
                    if (id[t] == id_vals[i]) {
                        real scalar t_pos4
                        t_pos4 = 0
                        real scalar tt4
                        for (tt4 = 1; tt4 <= T; tt4++) {
                            if (time_vals[tt4] == time[t]) {
                                t_pos4 = tt4
                                break
                            }
                        }
                        if (t_pos4 > 0) {
                            indicator[t] = sim_mat[t_pos4, j] * X[t, kk]
                        }
                    }
                }
                if (sum(abs(indicator)) > 0) {
                    vname = prefix + xnames[kk] + "_" + strofreal(id_vals[i]) + "_" + strofreal(time_vals[j+1])
                    (void) st_addvar("double", vname)
                    st_store(., vname, touse, indicator)
                    cnt++
                }
            }
        }
    }
    printf("{txt}  CFESIS: generated %g indicators (%g vars x %g units x %g periods)\n",
           cnt, K, N, T-1)
}

// ============================================================================
// xtgets_gen_tis: Trend Indicator Saturation
// Block-diagonal trend matrices: gets::tim(T) per unit
// Replicates R isatpanel tis logic
// ============================================================================
void xtgets_gen_tis(string scalar idvar, string scalar tvar,
                     string scalar prefix, string scalar touse)
{
    real colvector id, time
    real matrix id_vals, time_vals
    real scalar N, T, n, i, j, t, k
    string scalar vname
    real colvector indicator
    real matrix tim_mat
    
    st_view(id, ., idvar, touse)
    st_view(time, ., tvar, touse)
    n = rows(id)
    
    id_vals = uniqrows(id)
    time_vals = uniqrows(time)
    N = rows(id_vals)
    T = rows(time_vals)
    
    tim_mat = xtgets_tim(T)
    
    k = 0
    for (i = 1; i <= N; i++) {
        for (j = 1; j <= T-1; j++) {
            indicator = J(n, 1, 0)
            for (t = 1; t <= n; t++) {
                if (id[t] == id_vals[i]) {
                    real scalar t_pos5
                    t_pos5 = 0
                    real scalar tt5
                    for (tt5 = 1; tt5 <= T; tt5++) {
                        if (time_vals[tt5] == time[t]) {
                            t_pos5 = tt5
                            break
                        }
                    }
                    if (t_pos5 > 0) {
                        indicator[t] = tim_mat[t_pos5, j]
                    }
                }
            }
            if (sum(abs(indicator)) > 0) {
                vname = prefix + strofreal(id_vals[i]) + "_" + strofreal(time_vals[j+1])
                (void) st_addvar("double", vname)
                st_store(., vname, touse, indicator)
                k++
            }
        }
    }
    printf("{txt}  TIS: generated %g trend indicators (%g units x %g periods)\n",
           k, N, T-1)
}

// ============================================================================
// tsort: Sort variables by absolute t-statistic
// EXACT COPY from gets.ado (Clarke, 2013)
// Returns the n-th smallest |t| variable position
// ============================================================================
void tsort(real matrix B, real matrix V, real scalar num)
{
    real vector se, t
    real matrix X
    real scalar dimn
    real vector a
    
    se = diagonal(V)
    se = sqrt(se)
    t = abs(B' :/ se)
    dimn = length(t)
    
    if (dimn <= 1) {
        _error(3202)
    }
    
    // Exclude last element (constant/cons)
    t = t[|1 \ dimn-1|]
    a = 1::dimn-1
    X = (t, a)
    X = sort(X, 1)
    
    if (num > rows(X)) {
        _error(3201)
    }
    
    st_numscalar("e(t)", X[num, 1])
    st_numscalar("e(var)", X[num, 2])
}

end
