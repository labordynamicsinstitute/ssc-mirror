* pocoint lookup tables - sourced from Python arch package
* (Hansen-Haug response surface, simulated by K. Sheppard)
* Test IDs:  1=Za, 2=Zt, 3=Pu, 4=Pz
* Trend IDs: 1=n,  2=c,  3=ct, 4=ctt
*
* Tables are loaded from pocoint_cv_table.dta and pocoint_pv_table.dta,
* which must be in the ado-path alongside this file.

mata:
mata set matastrict off

real matrix pocoint_load_dta(string scalar fname, string scalar varlist)
{
    real matrix M
    string scalar full
    real scalar rc

    rc = _stata("findfile " + fname, 1)
    if (rc) {
        _error(3300, fname + " not found in adopath - reinstall pocoint package")
    }
    full = st_global("r(fn)")
    stata("preserve")
    stata("quietly use " + char(34) + full + char(34) + ", clear")
    M = st_data(., varlist)
    stata("restore")
    return(M)
}

real matrix pocoint_cv_table()
{
    return(pocoint_load_dta("pocoint_cv_table.dta",
        "test trend num minN cv1_a0 cv1_a1 cv1_a2 cv1_a3 cv5_a0 cv5_a1 cv5_a2 cv5_a3 cv10_a0 cv10_a1 cv10_a2 cv10_a3"))
}

real matrix pocoint_pv_table()
{
    return(pocoint_load_dta("pocoint_pv_table.dta",
        "test trend num tau_max tau_min tau_star lp_a0 lp_a1 lp_a2 lp_a3 sp_a0 sp_a1 sp_a2"))
}

real rowvector pocoint_cv_lookup(real scalar test_id, real scalar trend_id, real scalar num, real scalar nobs)
{
    real matrix    M
    real colvector hits
    real rowvector row, x, out
    real scalar    i, k

    M = pocoint_cv_table()
    hits = J(0,1,.)
    k = rows(M)
    for (i = 1; i <= k; i++) {
        if (M[i,1] == test_id & M[i,2] == trend_id & M[i,3] == num) {
            hits = hits \ i
            break
        }
    }
    if (rows(hits) == 0) {
        out = (., ., ., .)
        return(out)
    }
    row = M[hits[1], .]
    x = (1, 1/nobs, 1/(nobs^2), 1/(nobs^3))
    out = (row[1,5..8] * x', row[1,9..12] * x', row[1,13..16] * x', row[1,4])
    return(out)
}

real scalar pocoint_pval(real scalar stat, real scalar test_id, real scalar trend_id, real scalar num)
{
    real matrix M
    real rowvector row, params, x
    real scalar i, k, s, tau_max, tau_min, tau_star, order

    M = pocoint_pv_table()
    k = rows(M)
    for (i = 1; i <= k; i++) {
        if (M[i,1] == test_id & M[i,2] == trend_id & M[i,3] == num) break
    }
    if (i > k) return(.)
    row = M[i, .]
    s = stat
    if (test_id == 3 | test_id == 4) s = -s
    tau_max  = row[1,4]
    tau_min  = row[1,5]
    tau_star = row[1,6]
    if (s > tau_max) return(1)
    if (s < tau_min) return(0)
    if (s > tau_star) {
        params = row[1,7..10]
        order = 4
    }
    else {
        params = row[1,11..13]
        order = 3
    }
    x = J(1, order, 0)
    for (i = 1; i <= order; i++) x[1,i] = s^(i-1)
    return(normal(params * x'))
}

end
