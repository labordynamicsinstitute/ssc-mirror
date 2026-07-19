*! version 1.3.0  17jul2026  kperrony
*! Kejriwal-Perron (2010, JBES) tests for multiple structural changes in
*! cointegrated regressions and Kejriwal-Perron-Yu (2021, JTSA) two-step
*! partial parameter stability tests
*! Port of the original MATLAB code by Xuewen Yu (June 2021), Pierre Perron
*! code archive, to Stata/Mata. Author: Ozan Eruygur

program define kperrony, rclass
    version 14.0
    syntax varlist(numeric ts min=2) [if] [in] [, XZero(varlist numeric ts) LAGs(integer 4) TRend NODOLS NOENDO NOSC LEVel(real 95) NOTWOstep NOAKtest AKREPs(integer 10000) SEED(integer -1) PMseed(integer 0) FULLprecision]

    * ---------- parse variables (allow time-series operators) ----------
    local origvl `varlist'
    tsrevar `varlist'
    local vlist `r(varlist)'
    gettoken yvar zvars : vlist
    gettoken origy origz : origvl
    local xvars ""
    local origx ""
    if "`xzero'" != "" {
        local origx `xzero'
        tsrevar `xzero'
        local xvars `r(varlist)'
    }

    marksample touse
    markout `touse' `zvars' `xvars'

    * ---------- tsset checks ----------
    quietly tsset
    if "`r(panelvar)'" != "" {
        di as error "kperrony requires time-series data (tsset without a panel variable)"
        exit 198
    }
    local tvar `r(timevar)'
    local tdelta = r(tdelta)
    quietly count if `touse'
    local T0 = r(N)
    if `T0' == 0 error 2000
    quietly summarize `tvar' if `touse', meanonly
    local tmin = r(min)
    local tmax = r(max)
    if (`tmax' - `tmin')/`tdelta' + 1 != `T0' {
        di as error "estimation sample contains gaps in `tvar'"
        exit 198
    }

    * ---------- dimensions and critical value availability ----------
    local q : word count `zvars'
    local p : word count `xvars'
    local ok = 0
    if `p' == 0 & inrange(`q', 1, 4) local ok = 1
    if `p' == 1 & inrange(`q', 1, 2) local ok = 1
    if `p' == 2 & inrange(`q', 1, 2) local ok = 1
    if !`ok' {
        di as error "critical values are available only for p=0 with q=1..4 and (p,q) in {(1,1),(1,2),(2,1),(2,2)}, where q is the number of I(1) regressors and p the number of I(0) regressors in xzero()"
        exit 198
    }

    * ---------- significance level ----------
    local sig ""
    if `level' == 90 local sig "0.10"
    if `level' == 95 local sig "0.05"
    if `level' == 97.5 local sig "0.025"
    if `level' == 99 local sig "0.01"
    if "`sig'" == "" {
        di as error "level() must be 90, 95, 97.5, or 99"
        exit 198
    }

    * ---------- options ----------
    local optr = ("`trend'" != "")
    local sc = ("`nosc'" == "")
    if "`noendo'" != "" local nodols nodols
    local endo = ("`nodols'" == "")
    if `endo' {
        if `lags' < 1 | `lags' > 12 {
            di as error "lags() must be between 1 and 12"
            exit 198
        }
        local lT = `lags'
    }
    else local lT = 0
    local dots = ("`notwostep'" == "")
    local doak = ("`noaktest'" == "")
    if `akreps' < 10 | `akreps' > 100000 {
        di as error "akreps() must be between 10 and 100000"
        exit 198
    }
    if `seed' >= 0 set seed `seed' 

    * ---------- minimal sample checks ----------
    if `endo' local Te = `T0' - 2*`lT' - 1
    else local Te = `T0'
    local pq = 1 + `p' + `q'
    local hh = round(0.15*`Te')
    if `hh' < `pq' + 2 {
        di as error "effective sample too small for trimming 0.15 with `pq' breaking coefficients"
        exit 198
    }

    * ---------- Mata engine ----------
    mata: kperrony_main("`yvar'", "`zvars'", "`xvars'", "`touse'", `lT', `endo', `sc', `optr', `sig', `dots', `doak', `akreps', `pmseed')

    local nb = __kp_nb
    local Teff = __kp_T
    local heff = __kp_h
    local lagdim = __kp_lagdim

    * ---------- display ----------
    local dfmt %12.3f
    local wS = 12
    local HL1 = 50
    local HL2 = 41
    local HL3 = 62
    local HLC = 70
    local HLA = 62
    if "`fullprecision'" != "" {
        local dfmt %21.0g
        local wS = 21
        local HL1 = 68
        local HL2 = 50
        local HL3 = 71
        local HLC = 66
        local HLA = 66
    }
    local tfmt : format `tvar'
    di
    di as text "Kejriwal-Perron (2010) tests for multiple structural changes in cointegrated regression"
    local ds1 : di `tfmt' `tmin'
    local ds2 : di `tfmt' `tmax'
    di as text "Sample: " as result trim("`ds1'") as text " - " as result trim("`ds2'") as text "   T = " as result `T0' as text ", effective T = " as result `Teff'
    di as text "Trimming: " as result "0.15" as text " (h = " as result `heff' as text ")   Maximum breaks: " as result "5" as text "   Significance level: " as result `=100-`level'' as text "%"
    if `endo' di as text "Endogeneity correction: " as result "DOLS with `lT' leads/lags" as text " (`lagdim' columns)"
    else di as text "Endogeneity correction: " as result "none (static regression)"
    if `sc' di as text "Serial correlation correction: " as result "yes (hybrid QS long-run variance)"
    else di as text "Serial correlation correction: " as result "no"
    di as text "Dependent variable: " as result "`origy'" as text "   I(1) regressors (q=`q'): " as result "`origz'"
    if `p' > 0 di as text "I(0) regressors (p=`p'): " as result "`origx'"
    di
    di as text "[1] Kejriwal-Perron (2010) tests of H0: no structural change in the cointegrating equation"
    di as text "{hline `HL1'}"
    di as text "    k  " %`wS's "supF(k)" "     " %12s "crit. value" "  " %`wS's "SSR(k)"
    di as text "{hline `HL1'}"
    forvalues k = 1/5 {
        _kp_stars `=__kp_supf[`k',1]' `=__kp_cvk4[1,`k']' `=__kp_cvk4[2,`k']' `=__kp_cvk4[3,`k']' `=__kp_cvk4[4,`k']'
        di as text %5.0f `k' "  " as result `dfmt' `=__kp_supf[`k',1]' as result %-4s "`st'" as text " " as result %12.2f `=__kp_cvk[`k',1]' as text "  " as result `dfmt' `=__kp_ssr[`k',1]'
    }
    di as text "{hline `HL1'}"
    _kp_stars `=__kp_udmax' `=__kp_ud4[1,1]' `=__kp_ud4[2,1]' `=__kp_ud4[3,1]' `=__kp_ud4[4,1]'
    di as text "UDmax  " as result `dfmt' `=__kp_udmax' as result %-4s "`st'" as text " " as result %12.2f `=__kp_udcv'
    di as text "{hline `HL1'}"
    if `=__kp_udmax' > `=__kp_udcv' {
        di as text "    Decision: UDmax = " as result %9.3f `=__kp_udmax' as text " > cv = " as result %8.2f `=__kp_udcv' as text " -> at least one break at the `=100-`level''% level;"
        di as text "    the sequential procedure in [2] selects how many."
    }
    else {
        di as text "    Decision: UDmax = " as result %9.3f `=__kp_udmax' as text " <= cv = " as result %8.2f `=__kp_udcv' as text " -> no structural break is detected"
        di as text "    at the `=100-`level''% level."
    }
    di as text "Estimated break dates by number of breaks k (last observation of each regime):"
    forvalues k = 1/5 {
        local dl ""
        forvalues r = 1/`k' {
            local idx = __kp_dv[`r',`k']
            local tval = `tmin' + (`idx' - 1)*`tdelta'
            local dst : di `tfmt' `tval'
            local dst = trim("`dst'")
            local dl "`dl' `dst'"
        }
        di as text "  k=" as result `k' as text ":" as result "`dl'"
    }
    di
    if `nb' == 0 {
        di as text "UDmax test does not reject: no structural breaks detected."
    }
    else {
        di as text "[2] Sequential procedure SEQ(k+1|k) for selecting the number of breaks:"
        di as text "{hline `HL2'}"
        di as text "  " %-10s "test" %`wS's "statistic" "     " %12s "crit. value"
        di as text "{hline `HL2'}"
        local nseq = rowsof(__kp_seq)
        forvalues j = 1/`nseq' {
            local kk = __kp_seq[`j',1]
            local lab "SEQ(`=`kk'+1'|`kk')"
            _kp_stars `=__kp_seq[`j',2]' `=__kp_seqcv4[1,`kk']' `=__kp_seqcv4[2,`kk']' `=__kp_seqcv4[3,`kk']' `=__kp_seqcv4[4,`kk']'
            di as text "  " %-10s "`lab'" as result `dfmt' `=__kp_seq[`j',2]' as result %-4s "`st'" as text " " as result %12.2f `=__kp_seq[`j',3]'
        }
        di as text "{hline `HL2'}"
        di
        di as text "    Decision: SEQ selects " as result `nb' as text " break(s) at the `=100-`level''% level."
        di
        di as text "[3] Estimated break dates and regime-wise coefficients:"
        forvalues j = 1/`nb' {
            local idx = __kp_brdate[`j',1]
            local tval = `tmin' + (`idx' - 1)*`tdelta'
            local dst : di `tfmt' `tval'
            di as text "  Break `j': last observation of regime `j' = " as result trim("`dst'") as text " (obs " as result `idx' as text " of the sample)"
        }
    }
    di
    local zq = invnormal(1 - (100 - `level')/200)
    di as text "Regime-wise coefficient estimates with HAC standard errors:"
    di as text "{hline `HLC'}"
    if "`fullprecision'" != "" di as text "  Regime  coefficient  " %21s "estimate" " " %21s "HAC s.e."
            else di as text "  Regime  coefficient  " %12s "estimate" %12s "HAC s.e." %23s "[`level'% conf. interval]"
    di as text "{hline `HLC'}"
    local cnames _cons `origx' `origz'
    local nreg = `nb' + 1
    forvalues j = 1/`nreg' {
        forvalues c = 1/`pq' {
            local cn : word `c' of `cnames'
            local bv = __kp_coef[`j',`c']
            local sv = __kp_hacse[`j',`c']
            if "`fullprecision'" != "" di as text %7.0f `j' "  " %-14s "`cn'" as result %21.0g `bv' as result " " %21.0g `sv'
            else {
                local lo = `bv' - `zq'*`sv'
                local hi = `bv' + `zq'*`sv'
                di as text %7.0f `j' "  " %-14s "`cn'" as result %12.3f `bv' as result %12.3f `sv' as result %12.3f `lo' as result %11.3f `hi'
            }
        }
        if `j' < `nreg' di as text "{hline `HLC'}"
    }
    di as text "{hline `HLC'}"
    di as text "  HAC standard errors: quadratic spectral kernel with automatic bandwidth"
    di as text "  (Andrews 1991), as in the empirical application of KPY (2021)."
    if `dots' & `nb' > 0 {
        di
        di as text "[4] Kejriwal-Perron-Yu (2021) two-step partial stability tests (step 2, chi-squared):"
        di as text "{hline `HL3'}"
        di as text "  " %-16s "coefficient" %`wS's "F statistic" "  " %12s "chi2 c.v." "  " %4s "df"
        di as text "{hline `HL3'}"
        local cnames _cons `origx' `origz'
        forvalues c = 1/`pq' {
            local cn : word `c' of `cnames'
            local decision = cond(`=__kp_ts[`c',1]' > `=__kp_ts[`c',2]', "unstable", "stable")
            if "`decision'" == "unstable" local unstl "`unstl' `cn'"
            di as text "  " %-16s "`cn'" as result `dfmt' `=__kp_ts[`c',1]' as text "  " as result %12.3f `=__kp_ts[`c',2]' as text "  " as result %4.0f `=__kp_ts[`c',3]' as text "   `decision'"
        }
        di as text "{hline `HL3'}"
        di as text "H0: coefficient is stable across regimes, allowing all other coefficients to break at the estimated dates."
        if "`unstl'" != "" di as text "    Decision: coefficients found unstable at the `=100-`level''% level:" as result "`unstl'"
        else di as text "    Decision: no individual coefficient is found unstable at the `=100-`level''% level."
    }

    if "`noaktest'" == "" {
        di
        di as text "[5] Arai-Kurozumi (2007) test of the null of cointegration with the estimated breaks:"
        di as text "{hline `HLA'}"
        if "`fullprecision'" != "" di as text "  AK statistic = " as result %21.0g `=__kp_ak' as text "   simulated cv (`=100-`level''%) = " as result %21.0g `=__kp_akcv'
        else di as text "  AK statistic = " as result %9.3f `=__kp_ak' as text "   simulated cv (`=100-`level''%) = " as result %9.3f `=__kp_akcv'
        di as text "{hline `HLA'}"
        if `=__kp_ak' > `=__kp_akcv' {
            di as text "    Decision: the null of cointegration (with the estimated breaks) is"
            di as text "    rejected at the `=100-`level''% level; the regime-wise regression may be"
            di as text "    spurious and the results above should be interpreted with caution."
        }
        else {
            di as text "    Decision: the null of cointegration with the estimated breaks is not"
            di as text "    rejected at the `=100-`level''% level."
        }
        di as text "    Critical value simulated from the asymptotic distribution at the"
        di as text "    estimated break fractions (`akreps' replications)."
    }
    di
    di as text "Note: the tests presuppose that the regressors are I(1) and the errors are I(0)"
    di as text "throughout the sample. Shifts in the persistence of the individual series can be"
    di as text "tested with the kypshift package (Kejriwal-Yu-Perron 2020), available from SSC."
    * ---------- returned results ----------
    tempname supftab seqtab brtab coeftab tstab kcol
    matrix `kcol' = J(5,1,.)
    forvalues k = 1/5 {
        matrix `kcol'[`k',1] = `k'
    }
    matrix `supftab' = `kcol', __kp_supf, __kp_cvk, __kp_ssr
    matrix colnames `supftab' = k supF cv SSR
    return matrix supf = `supftab'
    if `nb' > 0 {
        matrix `seqtab' = __kp_seq
        matrix colnames `seqtab' = k SEQ cv
        return matrix seq = `seqtab'
        matrix `brtab' = J(`nb', 2, .)
        forvalues j = 1/`nb' {
            matrix `brtab'[`j',1] = __kp_brdate[`j',1]
            matrix `brtab'[`j',2] = `tmin' + (__kp_brdate[`j',1] - 1)*`tdelta'
        }
        matrix colnames `brtab' = obs tvalue
        return matrix brdates = `brtab'
    }
    matrix `coeftab' = __kp_coef
    tempname setab sdtab
    matrix `setab' = __kp_hacse
    return matrix hacse = `setab'
    matrix `sdtab' = __kp_stdse
    return matrix stdse = `sdtab'
    return matrix coef = `coeftab'
    if `dots' & `nb' > 0 {
        matrix `tstab' = __kp_ts
        matrix colnames `tstab' = F chi2cv df
        return matrix twostep = `tstab'
    }
    return matrix datevec = __kp_dv
    if "`noaktest'" == "" {
        return scalar ak = __kp_ak
        return scalar akcv = __kp_akcv
        return scalar akreps = `akreps'
    }
    return scalar nb = `nb'
    return scalar udmax = __kp_udmax
    return scalar udmax_cv = __kp_udcv
    return scalar T = `T0'
    return scalar Teff = `Teff'
    return scalar h = `heff'
    return scalar lags = `lT'
    return scalar p = `p'
    return scalar q = `q'
    return scalar level = `level'
    return local coefnames "_cons `origx' `origz'"
    return local depvar "`origy'"
    return local cmd "kperrony"
    capture matrix drop __kp_supf __kp_cvk __kp_cvk4 __kp_ud4 __kp_seqcv4 __kp_ssr __kp_seq __kp_brdate __kp_coef __kp_dv __kp_ts __kp_hacse __kp_stdse
    capture scalar drop __kp_nb __kp_udmax __kp_udcv __kp_T __kp_h __kp_lagdim __kp_ak __kp_akcv
end


program define _kp_stars
    args v c1 c2 c3 c4
    if `v' > `c4' {
        c_local st "****"
    }
    else if `v' > `c3' {
        c_local st "***"
    }
    else if `v' > `c2' {
        c_local st "**"
    }
    else if `v' > `c1' {
        c_local st "*"
    }
    else c_local st ""
end

mata:

// ------------------------------------------------------------------
// kperrony Mata engine: port of the MATLAB code accompanying
// Kejriwal-Perron (2010, JBES) and Kejriwal-Perron-Yu (2021, JTSA)
// (dating.m, ssr.m, parti.m, nldat.m, pzbar.m, olsqr.m, leadslag.m,
//  UDmax.m, seq_nbr.m, pvdel.m, correct.m, psigmq.m, spflp1.m,
//  onebp.m, pftest.m, twostep.m, get_UDcv.m, get_SEQcv.m)
// MATLAB left-to-right operation order is preserved where feasible.
// ------------------------------------------------------------------

void kperrony_olsqr(real colvector y, real matrix X, b, res)
{
    b = (luinv(X'*X)*X')*y
    res = y - X*b
}

real matrix kperrony_pzbar(real matrix zz, real scalar m, real colvector bb)
{
    real scalar nt, q1, i, d, prev
    real matrix zb
    nt = rows(zz)
    q1 = cols(zz)
    zb = J(nt, (m+1)*q1, 0)
    prev = 0
    for (i=1; i<=m; i++) {
        d = bb[i]
        zb[|prev+1, (i-1)*q1+1 \ d, i*q1|] = zz[|prev+1, 1 \ d, q1|]
        prev = d
    }
    zb[|prev+1, m*q1+1 \ nt, (m+1)*q1|] = zz[|prev+1, 1 \ nt, q1|]
    return(zb)
}

real matrix kperrony_leadslag(real matrix z, real scalar lT)
{
    real matrix dz, zlag, lead, lag
    real scalar n, i
    dz = z[|2, 1 \ rows(z), cols(z)|] - z[|1, 1 \ rows(z)-1, cols(z)|]
    n = rows(dz)
    zlag = dz[|lT+1, 1 \ n-lT, cols(dz)|]
    for (i=1; i<=lT; i++) {
        lead = dz[|lT+1+i, 1 \ n-lT+i, cols(dz)|]
        lag  = dz[|lT+1-i, 1 \ n-lT-i, cols(dz)|]
        zlag = lag, zlag, lead
    }
    return(zlag)
}

real colvector kperrony_ssrvec(real scalar start, real colvector y, real matrix z, real scalar h, real scalar last)
{
    real scalar bigt, r, v, f
    real colvector vec, delta1, invz, y0, res
    real matrix inv1, Z0
    real rowvector zr
    bigt = rows(y)
    vec = J(bigt, 1, 0)
    Z0 = z[|start, 1 \ start+h-1, cols(z)|]
    y0 = y[|start \ start+h-1|]
    inv1 = luinv(Z0'*Z0)
    delta1 = inv1*(Z0'*y0)
    res = y0 - Z0*delta1
    vec[start+h-1] = res'*res
    for (r=start+h; r<=last; r++) {
        zr = z[r, .]
        v = y[r] - zr*delta1
        invz = inv1*zr'
        f = 1 + zr*invz
        delta1 = delta1 + invz*(v/f)
        inv1 = inv1 - (invz*invz')/f
        vec[r] = vec[r-1] + v*v/f
    }
    return(vec)
}

real scalar kperrony_bigidx(real scalar i, real scalar j, real scalar bigt)
{
    return((i-1)*bigt - i*(i-1)/2 + j)
}

real colvector kperrony_bigvec(real colvector y, real matrix z, real scalar h, real scalar bigt)
{
    real colvector bigvec, vec
    real scalar i, j
    bigvec = J(bigt*(bigt+1)/2, 1, 0)
    for (i=1; i<=bigt-h+1; i++) {
        vec = kperrony_ssrvec(i, y, z, h, bigt)
        for (j=i; j<=bigt; j++) bigvec[kperrony_bigidx(i, j, bigt)] = vec[j]
    }
    return(bigvec)
}

void kperrony_minfirst(real colvector v, real scalar lo, real scalar hi, mval, midx)
{
    real scalar k
    mval = v[lo]
    midx = lo
    for (k=lo+1; k<=hi; k++) {
        if (v[k] < mval) {
            mval = v[k]
            midx = k
        }
    }
}

void kperrony_parti(real scalar start, real scalar b1, real scalar b2, real scalar last, real colvector bigvec, real scalar bigt, ssrmin, dx)
{
    real colvector dvec
    real scalar j
    dvec = J(bigt, 1, .)
    for (j=b1; j<=b2; j++) dvec[j] = bigvec[kperrony_bigidx(start, j, bigt)] + bigvec[kperrony_bigidx(j+1, last, bigt)]
    kperrony_minfirst(dvec, b1, b2, ssrmin, dx)
}

void kperrony_dating(real colvector y, real matrix z, real scalar h, real scalar m, real scalar bigt, glb, datevec)
{
    real matrix optdat, optssr
    real colvector bigvec, dvec
    real scalar j1, s, d, ib, jlast, jb, mv, mi, i, xx
    datevec = J(m, m, 0)
    optdat = J(bigt, m, 0)
    optssr = J(bigt, m, 0)
    glb = J(m, 1, 0)
    bigvec = kperrony_bigvec(y, z, h, bigt)
    if (m == 1) {
        s = .
        d = .
        kperrony_parti(1, h, bigt-h, bigt, bigvec, bigt, s, d)
        datevec[1,1] = d
        glb[1] = s
        return
    }
    for (j1=2*h; j1<=bigt; j1++) {
        s = .
        d = .
        kperrony_parti(1, h, j1-h, j1, bigvec, bigt, s, d)
        optssr[j1,1] = s
        optdat[j1,1] = d
    }
    glb[1] = optssr[bigt,1]
    datevec[1,1] = optdat[bigt,1]
    for (ib=2; ib<=m; ib++) {
        if (ib == m) {
            jlast = bigt
            dvec = J(bigt, 1, .)
            for (jb=ib*h; jb<=jlast-h; jb++) dvec[jb] = optssr[jb,ib-1] + bigvec[kperrony_bigidx(jb+1, bigt, bigt)]
            mv = .
            mi = .
            kperrony_minfirst(dvec, ib*h, jlast-h, mv, mi)
            optssr[jlast,ib] = mv
            optdat[jlast,ib] = mi
        }
        else {
            for (jlast=(ib+1)*h; jlast<=bigt; jlast++) {
                dvec = J(bigt, 1, .)
                for (jb=ib*h; jb<=jlast-h; jb++) dvec[jb] = optssr[jb,ib-1] + bigvec[kperrony_bigidx(jb+1, jlast, bigt)]
                mv = .
                mi = .
                kperrony_minfirst(dvec, ib*h, jlast-h, mv, mi)
                optssr[jlast,ib] = mv
                optdat[jlast,ib] = mi
            }
        }
        datevec[ib,ib] = optdat[bigt,ib]
        for (i=1; i<=ib-1; i++) {
            xx = ib - i
            datevec[xx,ib] = optdat[datevec[xx+1,ib], xx]
        }
        glb[ib] = optssr[bigt,ib]
    }
}

void kperrony_nldat(real colvector y, real matrix z, real matrix x, real scalar h, real scalar m, real scalar bigt, glb, datevec)
{
    real scalar p, q, mi, ssr1, ssrn, len, it
    real matrix zz, zbar, xbar, XX, d0, d1
    real colvector g0, g1, teta, teta1, delta1, beta1, e, res, rtmp
    p = cols(x)
    q = cols(z)
    glb = J(m, 1, 0)
    datevec = J(m, m, 0)
    for (mi=1; mi<=m; mi++) {
        zz = x, z
        g0 = J(0,1,0)
        d0 = J(0,0,0)
        kperrony_dating(y, zz, h, mi, bigt, g0, d0)
        zbar = kperrony_pzbar(z, mi, d0[|1,mi \ mi,mi|])
        xbar = kperrony_pzbar(x, mi, d0[|1,mi \ mi,mi|])
        teta = J(0,1,0)
        rtmp = J(0,1,0)
        kperrony_olsqr(y, (zbar, xbar), teta, rtmp)
        delta1 = teta[|1 \ q*(mi+1)|]
        beta1 = J(0,1,0)
        kperrony_olsqr(y - zbar*delta1, x, beta1, rtmp)
        e = y - x*beta1 - zbar*delta1
        ssr1 = e'*e
        len = 99999999
        it = 1
        while (len > 1e-4) {
            g1 = J(0,1,0)
            d1 = J(0,0,0)
            kperrony_dating(y - x*beta1, z, h, mi, bigt, g1, d1)
            zbar = kperrony_pzbar(z, mi, d1[|1,mi \ mi,mi|])
            XX = x, zbar
            teta1 = J(0,1,0)
            res = J(0,1,0)
            kperrony_olsqr(y, XX, teta1, res)
            beta1 = teta1[|1 \ p|]
            ssrn = res'*res
            len = abs(ssrn - ssr1)
            if (it >= 20) _error("kperrony: iterative estimation of the partial model did not converge")
            it = it + 1
            ssr1 = ssrn
            glb[mi] = ssrn
            datevec[|1,mi \ mi,mi|] = d1[|1,mi \ mi,mi|]
        }
    }
}

real scalar kperrony_lrv(real colvector ur, real colvector uu)
{
    real scalar T, rho, a2, eband, sig, lam, j, d, kern
    real colvector eb, ef
    T = rows(ur)
    eb = uu[|1 \ T-1|]
    ef = uu[|2 \ T|]
    rho = (eb'*ef)/(eb'*eb)
    a2 = 4*rho^2/(1-rho)^4
    eband = 1.3221*(a2*T)^0.2
    sig = ur'*ur
    lam = 0
    for (j=1; j<=T-1; j++) {
        d = (j/eband)*1.2*pi()
        kern = ((sin(d)/d - cos(d))/(d^2))*3
        lam = lam + (ur[|1 \ T-j|]'*ur[|1+j \ T|])*kern
    }
    return((sig + 2*lam)/T)
}

real scalar kperrony_qskern(real scalar x)
{
    real scalar d
    d = 6*pi()*x/5
    return(3*(sin(d)/d - cos(d))/(d*d))
}

real scalar kperrony_bandw(real matrix vhat)
{
    real scalar nt, dd, a2n, a2d, i, b, sig, a2
    real colvector yv, xv, e
    nt = rows(vhat)
    dd = cols(vhat)
    a2n = 0
    a2d = 0
    for (i=1; i<=dd; i++) {
        yv = vhat[|2, i \ nt, i|]
        xv = vhat[|1, i \ nt-1, i|]
        b = (xv'*yv)/(xv'*xv)
        e = yv - b*xv
        sig = (e'*e)/(nt-1)
        a2n = a2n + 4*b*b*sig*sig/(1-b)^8
        a2d = a2d + sig*sig/(1-b)^4
    }
    a2 = a2n/a2d
    return(1.3221*(a2*nt)^0.2)
}

real matrix kperrony_jhatpr(real matrix vmat)
{
    real scalar nt, dd, st, j
    real matrix jhat
    nt = rows(vmat)
    dd = cols(vmat)
    st = kperrony_bandw(vmat)
    jhat = vmat'*vmat
    for (j=1; j<=nt-1; j++) jhat = jhat + kperrony_qskern(j/st)*(vmat[|j+1, 1 \ nt, dd|]'*vmat[|1, 1 \ nt-j, dd|])
    for (j=1; j<=nt-1; j++) jhat = jhat + kperrony_qskern(j/st)*(vmat[|1, 1 \ nt-j, dd|]'*vmat[|j+1, 1 \ nt, dd|])
    return(jhat/(nt-dd))
}

real matrix kperrony_correct(real matrix reg, real colvector res)
{
    return(kperrony_jhatpr(reg :* res))
}

real matrix kperrony_psigmq(real colvector res, real colvector b, real scalar i, real scalar nt)
{
    real matrix sig
    real colvector r
    real scalar prev, kk, d
    sig = J(i+1, i+1, 0)
    prev = 0
    for (kk=1; kk<=i; kk++) {
        d = b[kk]
        r = res[|prev+1 \ d|]
        sig[kk,kk] = (r'*r)/(d-prev)
        prev = d
    }
    r = res[|prev+1 \ nt|]
    sig[i+1,i+1] = (r'*r)/(nt-prev)
    return(sig)
}

real matrix kperrony_pvdel(real colvector y, real matrix z, real scalar i, real scalar q, real scalar bigt, real colvector b, real scalar robust, real matrix x, real scalar p, real scalar withb)
{
    real matrix zbar, reg, sig, gg, irr, hac, rseg
    real colvector delv, res
    real scalar K, ie, jj, d, prev
    zbar = kperrony_pzbar(z, i, b)
    delv = J(0,1,0)
    res = J(0,1,0)
    if (p == 0) {
        kperrony_olsqr(y, zbar, delv, res)
        reg = zbar
    }
    else {
        kperrony_olsqr(y, (zbar, x), delv, res)
        if (withb == 0) reg = zbar - x*(luinv(x'*x)*(x'*zbar))
        else reg = x, zbar
    }
    if (robust == 0) {
        if (p == 0) {
            sig = kperrony_psigmq(res, b, i, bigt)
            return((sig#I(q))*luinv(reg'*reg))
        }
        else {
            K = (i+1)*q + p*withb
            gg = J(K, K, 0)
            sig = kperrony_psigmq(res, b, i, bigt)
            prev = 0
            for (ie=1; ie<=i+1; ie++) {
                d = (ie<=i ? b[ie] : bigt)
                rseg = reg[|prev+1, 1 \ d, cols(reg)|]
                gg = gg + sig[ie,ie]*(rseg'*rseg)
                prev = d
            }
            irr = luinv(reg'*reg)
            return(irr*gg*irr)
        }
    }
    else {
        if (p == 0) {
            hac = J((i+1)*q, (i+1)*q, 0)
            prev = 0
            for (jj=1; jj<=i+1; jj++) {
                d = (jj<=i ? b[jj] : bigt)
                hac[|(jj-1)*q+1, (jj-1)*q+1 \ jj*q, jj*q|] = (d-prev)*kperrony_correct(z[|prev+1, 1 \ d, cols(z)|], res[|prev+1 \ d|])
                prev = d
            }
            irr = luinv(reg'*reg)
            return(irr*hac*irr)
        }
        else {
            hac = kperrony_correct(reg, res)
            irr = luinv(reg'*reg)
            return(bigt*(irr*hac*irr))
        }
    }
}

real matrix kperrony_rmat(real scalar i, real scalar k)
{
    real matrix rsub
    real scalar j
    rsub = J(i, i+1, 0)
    for (j=1; j<=i; j++) {
        rsub[j,j] = -1
        rsub[j,j+1] = 1
    }
    return(rsub#I(k))
}

void kperrony_udmax(real colvector y, real matrix X, real scalar M, real scalar p, real scalar pq, real scalar bigt, real matrix datevec, real matrix lls, real scalar lagdim, real scalar sc, UDF, supF)
{
    real scalar T, i, robust, lrv, fstar
    real matrix rmat, zbar, MG, vdel
    real colvector delta, uu, dbdel
    supF = J(M, 1, 0)
    T = rows(y)
    for (i=1; i<=M; i++) {
        rmat = kperrony_rmat(i, pq)
        zbar = kperrony_pzbar(X, i, datevec[|1,i \ i,i|])
        delta = J(0,1,0)
        uu = J(0,1,0)
        if (lagdim == 0) {
            kperrony_olsqr(y, zbar, delta, uu)
        }
        else {
            dbdel = J(0,1,0)
            kperrony_olsqr(y, (zbar, lls), dbdel, uu)
            delta = dbdel[|1 \ (i+1)*pq|]
        }
        if (p != 0) {
            robust = sc
            vdel = kperrony_pvdel(y, X, i, pq, bigt, datevec[|1,i \ i,i|], robust, lls, lagdim, 0)
            fstar = delta'*rmat'*luinv(rmat*vdel*rmat')*rmat*delta
            supF[i] = (bigt - (i+1)*pq - lagdim)*fstar/(bigt*i)
        }
        else {
            if (lagdim == 0) MG = I(T)
            else MG = I(T) - lls*luinv(lls'*lls)*lls'
            vdel = luinv(zbar'*MG*zbar)
            fstar = delta'*rmat'*luinv(rmat*vdel*rmat')*rmat*delta
            lrv = kperrony_lrv(uu, uu)
            supF[i] = (fstar/i)/lrv
        }
    }
    UDF = max(supF)
}

real scalar kperrony_spflp1p0(real colvector brdate, real scalar m, real colvector y, real matrix X, real scalar h, real scalar pq, real matrix zlag, real scalar lagdim, real scalar trim)
{
    real scalar T, SSR0, best, i, lo, hiend, Ti, hi, t1, s, lrv
    real colvector dv, b0, ur, b1, uut, uu, nbr
    real matrix Xbar, nXbar, D0, D1
    T = rows(y)
    dv = 0 \ brdate \ T
    Xbar = kperrony_pzbar(X, m-1, brdate)
    if (lagdim > 0) D0 = Xbar, zlag
    else D0 = Xbar
    b0 = J(0,1,0)
    ur = J(0,1,0)
    kperrony_olsqr(y, D0, b0, ur)
    SSR0 = ur'*ur
    best = .
    uu = ur
    for (i=1; i<=m; i++) {
        lo = dv[i] + 1
        hiend = dv[i+1]
        Ti = hiend - lo + 1
        hi = min((ceil(Ti*trim), pq+lagdim+1))
        t1 = lo + hi
        while (t1 <= hiend - hi + 1) {
            nbr = sort((brdate \ t1), 1)
            nXbar = kperrony_pzbar(X, m, nbr)
            if (lagdim > 0) D1 = nXbar, zlag
            else D1 = nXbar
            b1 = J(0,1,0)
            uut = J(0,1,0)
            kperrony_olsqr(y, D1, b1, uut)
            s = uut'*uut
            if (s < best) {
                best = s
                uu = uut
            }
            t1 = t1 + 1
        }
    }
    lrv = kperrony_lrv(ur, uu)
    return((SSR0 - best)/lrv)
}

void kperrony_onebp(real colvector y, real matrix z, real matrix x, real scalar h, real scalar start, real scalar last, ssrind, bd)
{
    real scalar i, bdat, rr, n
    real matrix zb, D, xs, zs
    real colvector bb, rres, ys
    ssrind = .
    bdat = .
    n = last - start + 1
    ys = y[|start \ last|]
    zs = z[|start, 1 \ last, cols(z)|]
    if (cols(x) > 0) xs = x[|start, 1 \ last, cols(x)|]
    else xs = J(n, 0, 0)
    i = h
    while (i <= n - h) {
        zb = kperrony_pzbar(zs, 1, J(1,1,i))
        D = xs, zb
        bb = J(0,1,0)
        rres = J(0,1,0)
        kperrony_olsqr(ys, D, bb, rres)
        rr = rres'*rres
        if (rr < ssrind) {
            ssrind = rr
            bdat = i
        }
        i = i + 1
    }
    bd = bdat + start - 1
}

real scalar kperrony_pftest(real colvector y, real matrix z, real scalar q, real scalar bigt, real scalar date, real scalar robust, real matrix x, real scalar p)
{
    real matrix rmat, zbar, vdel
    real colvector delta, dbdel, rr
    real scalar fstar
    rmat = kperrony_rmat(1, q)
    zbar = kperrony_pzbar(z, 1, J(1,1,date))
    delta = J(0,1,0)
    rr = J(0,1,0)
    if (p == 0) {
        kperrony_olsqr(y, zbar, delta, rr)
    }
    else {
        dbdel = J(0,1,0)
        kperrony_olsqr(y, (zbar, x), dbdel, rr)
        delta = dbdel[|1 \ 2*q|]
    }
    vdel = kperrony_pvdel(y, z, 1, q, bigt, J(1,1,date), robust, x, p, 0)
    fstar = delta'*rmat'*luinv(rmat*vdel*rmat')*rmat*delta
    return((bigt - 2*q - p)*fstar/bigt)
}

real scalar kperrony_spflp1(real colvector dt, real scalar nseg, real colvector y, real matrix z, real scalar h, real scalar q, real scalar robust, real matrix x, real scalar p)
{
    real scalar bigt, maxf, is, len, si, ds, f
    real colvector dv, yseg
    real matrix zseg, xseg
    bigt = rows(z)
    dv = 0 \ dt \ bigt
    maxf = 0
    for (is=1; is<=nseg; is++) {
        len = dv[is+1] - dv[is]
        if (len >= 2*h) {
            si = .
            ds = .
            kperrony_onebp(y, z, x, h, dv[is]+1, dv[is+1], si, ds)
            yseg = y[|dv[is]+1 \ dv[is+1]|]
            zseg = z[|dv[is]+1, 1 \ dv[is+1], cols(z)|]
            if (p == 0) f = kperrony_pftest(yseg, zseg, q, len, ds - dv[is], robust, J(len,0,0), 0)
            else {
                xseg = x[|dv[is]+1, 1 \ dv[is+1], cols(x)|]
                f = kperrony_pftest(yseg, zseg, q, len, ds - dv[is], robust, xseg, p)
            }
            if (f > maxf) maxf = f
        }
    }
    return(maxf)
}

real scalar kperrony_twostep(real colvector y, real matrix z, real matrix x, real matrix Xfull, real colvector testvec, real scalar nb, real colvector brdate, real scalar sc, real scalar endo, real scalar lT)
{
    real scalar i, testdim, K, c, lTe, lagdim, bigt, n0, p, robust, lagrestdim, fstar, lrv
    real colvector restvec, ebr, ye, dbdel, uu, delta, b0, ur
    real matrix Xtest, Xrest, zlag, Xrestbar, Xtest_e, Xrest_e, rmat, Xtestbar, D1, Xrz, vdel, D0
    i = nb
    testdim = rows(testvec)
    K = cols(Xfull)
    restvec = J(0, 1, 0)
    for (c=1; c<=K; c++) {
        if (!anyof(testvec, c)) restvec = restvec \ c
    }
    Xtest = Xfull[., testvec']
    if (rows(restvec) > 0) Xrest = Xfull[., restvec']
    else Xrest = J(rows(Xfull), 0, 0)
    if (endo == 0) {
        lTe = 0
        zlag = J(rows(y), 0, 0)
        lagdim = 0
        bigt = rows(y)
        ye = y
        ebr = brdate
        if (cols(Xrest) > 0) Xrestbar = kperrony_pzbar(Xrest, i, ebr)
        else Xrestbar = J(bigt, 0, 0)
        Xtest_e = Xtest
    }
    else {
        lTe = lT
        zlag = kperrony_leadslag(z, lTe)
        bigt = rows(zlag)
        lagdim = cols(zlag)
        n0 = rows(y)
        ye = y[|lTe+2 \ n0-lTe|]
        Xtest_e = Xtest[|lTe+2, 1 \ n0-lTe, cols(Xtest)|]
        ebr = brdate :- lTe
        if (cols(Xrest) > 0) {
            Xrest_e = Xrest[|lTe+2, 1 \ n0-lTe, cols(Xrest)|]
            Xrestbar = kperrony_pzbar(Xrest_e, i, ebr)
        }
        else Xrestbar = J(bigt, 0, 0)
    }
    rmat = kperrony_rmat(i, testdim)
    Xtestbar = kperrony_pzbar(Xtest_e, i, ebr)
    D1 = Xtestbar, Xrestbar, zlag
    dbdel = J(0,1,0)
    uu = J(0,1,0)
    kperrony_olsqr(ye, D1, dbdel, uu)
    delta = dbdel[|1 \ (i+1)*testdim|]
    p = cols(x) - 1
    if (p != 0) {
        robust = sc
        Xrz = Xrestbar, zlag
        lagrestdim = cols(Xrz)
        vdel = kperrony_pvdel(ye, Xtest_e, i, testdim, bigt, ebr, robust, Xrz, lagrestdim, 0)
        fstar = delta'*rmat'*luinv(rmat*vdel*rmat')*rmat*delta
        return((bigt - (i+1)*testdim - lagrestdim)*fstar/(bigt*i))
    }
    else {
        D0 = Xtest_e, Xrestbar, zlag
        b0 = J(0,1,0)
        ur = J(0,1,0)
        kperrony_olsqr(ye, D0, b0, ur)
        lrv = kperrony_lrv(ur, uu)
        return((ur'*ur - uu'*uu)/lrv)
    }
}

real scalar kperrony_pmu(state)
{
    state = mod(16807*state, 2147483647)
    return(state/2147483647)
}

void kperrony_pmnormfill(real matrix A, state)
{
    real scalar n, i, u1, u2, r, th, z1, z2
    n = rows(A)*cols(A)
    i = 1
    while (i <= n) {
        u1 = kperrony_pmu(state)
        u2 = kperrony_pmu(state)
        r = sqrt(-2*ln(u1))
        th = 2*pi()*u2
        z1 = r*cos(th)
        z2 = r*sin(th)
        A[mod(i-1, rows(A)) + 1, floor((i-1)/rows(A)) + 1] = z1
        i = i + 1
        if (i <= n) {
            A[mod(i-1, rows(A)) + 1, floor((i-1)/rows(A)) + 1] = z2
            i = i + 1
        }
    }
}

real scalar kperrony_akstats(real colvector y, real matrix x)
{
    real scalar T, k, nume, rho, a1, a2, bw, lam, sig, s, omega
    real matrix invxx
    real colvector b, res, sqcs
    T = rows(x)
    k = cols(x)
    invxx = luinv(x'*x)
    b = invxx*(x'*y)
    res = y - x*b
    sqcs = runningsum(res):^2
    nume = sum(sqcs)/T^2
    rho = (res[|1 \ T-1|]'*res[|2 \ T|])/(res[|1 \ T-1|]'*res[|1 \ T-1|])
    a1 = 1.1447*((4*rho^2*T)/((1+rho)^2*(1-rho)^2))^(1/3)
    a2 = 1.1447*((4*0.81*T)/((1.9)^2*(0.1)^2))^(1/3)
    bw = min((a1, a2))
    lam = 0
    sig = res'*res
    for (s=1; s<=floor(bw); s++) lam = lam + (1 - s/(floor(bw)+1))*(res[|s+1 \ T|]'*res[|1 \ T-s|])
    omega = (sig + 2*lam)/T
    return(nume/omega)
}

real scalar kperrony_akcv(real scalar q, real scalar brnum, real colvector brdate, real scalar T, real scalar siglev, real scalar mrep, real scalar pmseed)
{
    real scalar TT, mm, i, t1, t2, Glast, usepm, state
    real colvector lamv, V, w1, G, w1i, g1i, brvec, dw
    real matrix w2, w, wi, sV
    TT = 2000
    usepm = (pmseed > 0)
    state = pmseed
    if (brnum > 0) lamv = brdate/T
    else lamv = J(0, 1, 0)
    V = J(mrep, 1, 0)
    for (mm=1; mm<=mrep; mm++) {
        w1 = J(TT, 1, 0)
        w2 = J(TT, q, 0)
        if (usepm) {
            kperrony_pmnormfill(w1, state)
            kperrony_pmnormfill(w2, state)
        }
        else {
            w1 = rnormal(TT, 1, 0, 1)
            w2 = rnormal(TT, q, 0, 1)
        }
        w1 = runningsum(w1)/sqrt(TT)
        for (i=1; i<=q; i++) w2[., i] = runningsum(w2[., i])/sqrt(TT)
        w = J(TT, 1, 1), w2
        if (brnum > 0) brvec = 0 \ floor(lamv*TT) \ TT
        else brvec = 0 \ TT
        G = J(TT, 1, 0)
        for (i=1; i<=brnum+1; i++) {
            t1 = brvec[i] + 1
            t2 = brvec[i+1]
            wi = w[|t1, 1 \ t2, cols(w)|]
            w1i = w1[|t1 \ t2|]
            dw = 0 \ (w1i[|2 \ rows(w1i)|] - w1i[|1 \ rows(w1i)-1|])
            g1i = luinv(wi'*wi)*(wi'*dw)
            if (i != 1) Glast = G[t1-1]
            else Glast = 0
            G[|t1 \ t2|] = Glast :+ runningsum(wi*g1i)
        }
        V[mm] = mean((w1 - G):^2)
    }
    sV = sort(V, 1)
    return(sV[ceil((1-siglev)*mrep)])
}

void kperrony_regout(real colvector y, real matrix D, real scalar pq, real scalar nb, coefs, hacse, stdse)
{
    real scalar T, k, sigsq
    real matrix invxx, vmat, hacv, varcov
    real colvector b, res, hs, ss
    real scalar jj
    T = rows(D)
    k = cols(D)
    invxx = luinv(D'*D)
    b = invxx*(D'*y)
    res = y - D*b
    sigsq = (res'*res)/(T - k)
    varcov = sigsq*invxx
    vmat = D :* res
    hacv = T*invxx*kperrony_jhatpr(vmat)*invxx
    hs = J(k, 1, 0)
    ss = J(k, 1, 0)
    for (jj=1; jj<=k; jj++) {
        hs[jj] = sqrt(hacv[jj,jj])
        ss[jj] = sqrt(varcov[jj,jj])
    }
    coefs = J(nb+1, pq, 0)
    hacse = J(nb+1, pq, 0)
    stdse = J(nb+1, pq, 0)
    for (jj=1; jj<=nb+1; jj++) {
        coefs[jj, .] = b[|(jj-1)*pq+1 \ jj*pq|]'
        hacse[jj, .] = hs[|(jj-1)*pq+1 \ jj*pq|]'
        stdse[jj, .] = ss[|(jj-1)*pq+1 \ jj*pq|]'
    }
}

real matrix kperrony_udcvtab(real scalar p, real scalar q)
{
    if (p==0 & q==1) return((10.34, 8.85, 7.66, 6.66, 5.3, 10.53, 11.18, 9.25, 8.09, 6.95, 5.53, 11.33 \ 12.11, 9.96, 8.6, 7.36, 5.9, 12.25, 13.03, 10.39, 8.94, 7.6, 6.12, 13.07 \ 13.85, 11.41, 9.4, 7.99, 6.42, 13.91, 15.08, 11.49, 9.66, 8.28, 6.67, 15.13 \ 17.03, 12.41, 10.4, 8.71, 7.08, 17.4, 16.86, 12.73, 10.82, 8.95, 7.32, 16.86))
    else if (p==0 & q==2) return((12.36, 11.01, 9.6, 8.45, 6.96, 12.64, 11.88, 10.31, 9.0, 7.98, 6.62, 12.13 \ 14.3, 12.11, 10.41, 9.19, 7.64, 14.47, 13.63, 11.34, 9.94, 8.68, 7.31, 13.99 \ 15.72, 13.37, 11.26, 9.75, 8.15, 15.9, 15.51, 12.57, 10.86, 9.37, 7.92, 15.53 \ 17.67, 14.73, 12.21, 10.77, 8.82, 17.67, 17.31, 14.63, 12.1, 10.51, 8.73, 17.31))
    else if (p==0 & q==3) return((14.88, 12.84, 11.49, 10.19, 8.53, 15.09, 14.39, 12.14, 10.79, 9.61, 8.22, 14.65 \ 16.66, 14.11, 12.38, 10.94, 9.12, 16.71, 16.5, 13.22, 11.66, 10.33, 8.92, 16.61 \ 18.32, 15.24, 13.01, 11.52, 9.61, 18.35, 18.08, 14.45, 12.54, 11.04, 9.44, 18.24 \ 20.78, 16.29, 14.36, 12.37, 10.23, 20.78, 20.28, 15.55, 13.8, 12.02, 10.1, 20.28))
    else if (p==0 & q==4) return((16.87, 14.72, 13.2, 11.75, 9.9, 17.05, 16.27, 13.8, 12.41, 11.17, 9.62, 16.46 \ 19.08, 15.9, 14.15, 12.68, 10.72, 19.16, 18.36, 15.08, 13.38, 12.07, 10.28, 18.46 \ 20.81, 17.15, 15.21, 13.38, 11.43, 20.89, 20.52, 17.01, 14.33, 12.98, 10.93, 20.52 \ 22.59, 18.85, 16.44, 14.25, 11.98, 22.59, 23.12, 18.71, 15.77, 13.87, 11.72, 23.12))
    else if (p==1 & q==1) return((11.69, 9.88, 8.63, 7.52, 6.27, 11.99, 11.98, 10.29, 8.96, 7.83, 6.63, 12.27 \ 13.24, 10.96, 9.62, 8.29, 6.87, 13.43, 13.74, 11.64, 9.92, 8.66, 7.28, 14.06 \ 14.78, 12.1, 10.54, 8.99, 7.56, 14.87, 15.86, 12.85, 10.87, 9.3, 7.87, 15.91 \ 17.28, 13.4, 11.53, 9.75, 8.11, 17.39, 17.99, 14.27, 11.87, 10.2, 8.44, 17.99))
    else if (p==1 & q==2) return((13.85, 12.05, 10.48, 9.35, 7.99, 14.23, 13.42, 11.33, 10.06, 9.0, 7.73, 13.64 \ 15.91, 13.45, 11.5, 10.23, 8.64, 16.07, 15.42, 12.76, 11.03, 9.86, 8.44, 15.47 \ 17.68, 14.6, 12.44, 11.06, 9.3, 18.06, 17.5, 13.95, 12.05, 10.58, 8.97, 17.5 \ 19.89, 16.02, 13.8, 11.88, 10.14, 20.03, 19.61, 15.23, 13.05, 11.38, 9.59, 19.61))
    else if (p==2 & q==1) return((12.88, 11.06, 9.55, 8.53, 7.52, 13.26, 13.24, 11.17, 9.79, 8.85, 7.69, 13.51 \ 15.1, 12.13, 10.53, 9.42, 8.16, 15.25, 15.16, 12.19, 10.85, 9.61, 8.29, 15.2 \ 17.51, 13.04, 11.3, 9.98, 8.71, 17.6, 16.89, 13.33, 11.59, 10.48, 8.87, 16.89 \ 19.1, 14.68, 12.35, 11.07, 9.51, 19.1, 18.95, 14.43, 12.79, 11.23, 9.9, 18.95))
    else if (p==2 & q==2) return((14.82, 13.09, 11.64, 10.4, 9.04, 15.24, 14.91, 12.5, 11.14, 10.06, 8.83, 15.28 \ 17.02, 14.49, 12.51, 11.19, 9.73, 17.33, 17.17, 14.02, 12.23, 10.91, 9.59, 17.22 \ 19.59, 15.57, 13.39, 11.85, 10.29, 19.59, 19.48, 15.41, 13.18, 11.57, 10.23, 19.48 \ 21.66, 17.07, 14.35, 12.81, 10.85, 21.66, 21.46, 16.5, 14.18, 12.6, 10.82, 21.46))
    _error("kperrony: no critical values for this p,q combination")
}

real matrix kperrony_seqcvtab(real scalar p, real scalar q)
{
    if (p==0 & q==1) return((12.0, 12.94, 13.74, 14.53, 15.23, 12.94, 13.99, 14.93, 15.5, 15.73 \ 13.78, 15.25, 16.38, 17.02, 17.7, 15.01, 15.85, 16.53, 16.86, 17.04 \ 16.38, 17.7, 18.24, 18.53, 19.18, 16.53, 17.04, 17.17, 17.43, 18.04 \ 18.53, 19.33, 19.92, 20.5, 21.34, 17.43, 18.58, 19.11, 19.22, 19.54))
    else if (p==0 & q==2) return((14.26, 15.02, 15.64, 16.02, 16.51, 13.57, 14.78, 15.4, 15.87, 16.12 \ 15.65, 16.61, 17.12, 17.66, 17.85, 15.51, 16.18, 17.08, 17.31, 17.5 \ 17.12, 17.85, 18.22, 19.04, 19.27, 17.08, 17.5, 19.27, 19.62, 19.7 \ 19.04, 19.35, 19.9, 19.99, 20.01, 19.62, 19.79, 21.52, 22.58, 22.75))
    else if (p==0 & q==3) return((16.64, 17.57, 18.28, 18.86, 19.53, 16.38, 17.3, 17.92, 18.4, 18.62 \ 18.3, 19.58, 20.21, 20.77, 21.45, 17.99, 18.74, 19.77, 20.28, 20.89 \ 20.21, 21.45, 22.67, 23.36, 23.48, 19.77, 20.89, 21.56, 22.11, 22.28 \ 23.36, 23.52, 24.13, 24.43, 25.16, 22.11, 22.37, 22.83, 23.98, 24.54))
    else if (p==0 & q==4) return((18.96, 19.91, 20.68, 21.13, 21.51, 18.29, 19.54, 20.43, 20.97, 21.32 \ 20.8, 21.59, 22.36, 22.58, 23.12, 20.51, 21.81, 22.4, 23.12, 23.78 \ 22.36, 23.12, 24.1, 25.73, 26.11, 22.4, 23.78, 25.1, 25.75, 25.84 \ 25.73, 27.01, 27.43, 27.47, 27.75, 25.75, 26.36, 26.66, 26.86, 27.71))
    else if (p==1 & q==1) return((13.18, 13.92, 14.7, 15.08, 15.79, 13.72, 15.14, 15.72, 16.44, 16.75 \ 14.72, 15.82, 16.6, 17.28, 17.61, 15.73, 16.83, 17.54, 17.99, 18.17 \ 16.6, 17.61, 19.2, 19.43, 19.85, 17.54, 18.17, 19.27, 19.97, 20.53 \ 19.43, 20.02, 21.38, 21.43, 22.1, 19.97, 21.13, 22.77, 23.42, 23.98))
    else if (p==1 & q==2) return((15.82, 16.69, 17.59, 18.15, 18.39, 15.21, 16.54, 17.44, 17.98, 18.46 \ 17.68, 18.63, 19.37, 19.89, 20.39, 17.49, 18.49, 19.26, 19.61, 20.27 \ 19.37, 20.39, 21.48, 22.63, 22.84, 19.26, 20.27, 20.76, 21.69, 22.03 \ 22.63, 23.82, 24.73, 25.4, 25.62, 21.69, 22.37, 22.94, 24.08, 24.08))
    else if (p==2 & q==1) return((15.06, 16.32, 17.39, 17.83, 18.22, 15.09, 16.21, 16.85, 17.33, 17.85 \ 17.44, 18.25, 18.65, 19.1, 19.96, 16.86, 17.87, 18.81, 18.95, 19.28 \ 18.65, 19.96, 20.06, 20.37, 20.69, 18.81, 19.28, 19.66, 21.1, 21.43 \ 20.37, 20.73, 21.96, 23.13, 23.22, 21.1, 21.61, 22.74, 23.7, 24.12))
    else if (p==2 & q==2) return((16.95, 18.69, 19.46, 20.06, 20.44, 17.12, 18.56, 19.4, 19.92, 20.75 \ 19.48, 20.44, 21.33, 21.66, 21.97, 19.45, 20.42, 21.16, 21.46, 22.33 \ 21.33, 21.97, 22.39, 23.52, 24.03, 21.16, 21.86, 22.89, 23.41, 23.85 \ 23.52, 24.11, 24.75, 25.05, 25.12, 23.41, 23.85, 25.06, 25.94, 26.32))
    _error("kperrony: no critical values for this p,q combination")
}

real scalar kperrony_sigrow(real scalar sig)
{
    if (abs(sig - 0.10) < 1e-9) return(1)
    if (abs(sig - 0.05) < 1e-9) return(2)
    if (abs(sig - 0.025) < 1e-9) return(3)
    if (abs(sig - 0.01) < 1e-9) return(4)
    _error("kperrony: invalid significance level")
}

void kperrony_main(string scalar yname, string scalar znames, string scalar xnames, string scalar tousename, real scalar lT, real scalar endo, real scalar sc, real scalar optr, real scalar sig, real scalar dots, real scalar doak, real scalar akreps, real scalar pmseed)
{
    real colvector y, ye, glb, supF, e, brml, orig, bb, rr, cvk
    real matrix z, xraw, x, X, zlag, datevec, cvtab, seqtab, seqres, Xb, coefs, dvorig, tsres, Xfull, hacse, stdse, Dse
    real scalar T0, M, trim, p, q, T, h, pq, lagdim, lTe, UDF, UDcv, srow, nb, stopk, i, supfl, cvs, jj, kk, r2, c, Fv, df, cvchi, akstat, akcv
    y = st_data(., yname, tousename)
    z = st_data(., tokens(znames), tousename)
    if (xnames != "") xraw = st_data(., tokens(xnames), tousename)
    else xraw = J(rows(y), 0, 0)
    x = J(rows(y), 1, 1), xraw
    T0 = rows(y)
    M = 5
    trim = 0.15
    p = cols(x) - 1
    q = cols(z)
    glb = J(0,1,0)
    datevec = J(0,0,0)
    if (endo == 0) {
        X = x, z
        pq = cols(X)
        zlag = J(T0, 0, 0)
        lagdim = 0
        lTe = 0
        T = T0
        h = round(trim*T)
        kperrony_dating(y, X, h, M, T, glb, datevec)
        ye = y
    }
    else {
        lTe = lT
        zlag = kperrony_leadslag(z, lTe)
        T = rows(zlag)
        lagdim = cols(zlag)
        X = x[|lTe+2, 1 \ T0-lTe, cols(x)|], z[|lTe+2, 1 \ T0-lTe, cols(z)|]
        ye = y[|lTe+2 \ T0-lTe|]
        pq = cols(X)
        h = round(trim*T)
        kperrony_nldat(ye, X, zlag, h, M, T, glb, datevec)
    }
    UDF = .
    supF = J(0,1,0)
    kperrony_udmax(ye, X, M, p, pq, T, datevec, zlag, lagdim, sc, UDF, supF)
    cvtab = kperrony_udcvtab(p, q)
    srow = kperrony_sigrow(sig)
    UDcv = cvtab[srow, optr*6 + 6]
    cvk = cvtab[|srow, optr*6+1 \ srow, optr*6+5|]'
    seqtab = kperrony_seqcvtab(p, q)
    seqres = J(0, 3, 0)
    if (UDF <= UDcv) nb = 0
    else {
        stopk = 0
        i = 1
        nb = .
        while (stopk == 0 & i <= M) {
            if (p != 0) supfl = kperrony_spflp1(datevec[|1,i \ i,i|], i+1, ye, X, h, pq, sc, zlag, lagdim)
            else supfl = kperrony_spflp1p0(datevec[|1,i \ i,i|], i+1, ye, X, h, pq, zlag, lagdim, trim)
            cvs = seqtab[srow, optr*5 + i]
            seqres = seqres \ (i, supfl, cvs)
            if (supfl <= cvs) {
                stopk = 1
                nb = i
            }
            i = i + 1
        }
        if (i == M + 1) nb = M
    }
    if (nb > 0) {
        e = datevec[|1,nb \ nb,nb|]
        brml = e :+ lTe
        if (endo == 1) orig = e :+ (lTe + 1)
        else orig = e
    }
    else {
        e = J(0,1,0)
        brml = J(0,1,0)
        orig = J(0,1,0)
    }
    if (nb > 0) {
        Dse = kperrony_pzbar((x, z), nb, brml)
        if (endo == 1) Dse = Dse[|lTe+2, 1 \ T0-lTe, cols(Dse)|]
    }
    else Dse = X
    if (lagdim > 0) Dse = Dse, zlag
    coefs = J(0,0,0)
    hacse = J(0,0,0)
    stdse = J(0,0,0)
    kperrony_regout(ye, Dse, pq, nb, coefs, hacse, stdse)
    dvorig = J(M, M, .)
    for (kk=1; kk<=M; kk++) {
        for (r2=1; r2<=kk; r2++) {
            if (endo == 1) dvorig[r2,kk] = datevec[r2,kk] + lTe + 1
            else dvorig[r2,kk] = datevec[r2,kk]
        }
    }
    tsres = J(0, 3, .)
    if (dots & nb > 0) {
        Xfull = x, z
        for (c=1; c<=cols(Xfull); c++) {
            Fv = kperrony_twostep(y, z, x, Xfull, J(1,1,c), nb, brml, sc, endo, lTe)
            df = nb
            cvchi = invchi2(df, 1 - sig)
            tsres = tsres \ (Fv, cvchi, df)
        }
    }
    st_numscalar("__kp_nb", nb)
    st_numscalar("__kp_udmax", UDF)
    st_numscalar("__kp_udcv", UDcv)
    st_numscalar("__kp_T", T)
    st_numscalar("__kp_h", h)
    st_numscalar("__kp_lagdim", lagdim)
    st_matrix("__kp_supf", supF)
    st_matrix("__kp_cvk", cvk)
    st_matrix("__kp_cvk4", cvtab[|1, optr*6+1 \ 4, optr*6+5|])
    st_matrix("__kp_ud4", cvtab[|1, optr*6+6 \ 4, optr*6+6|])
    st_matrix("__kp_seqcv4", seqtab[|1, optr*5+1 \ 4, optr*5+5|])
    st_matrix("__kp_ssr", glb)
    st_matrix("__kp_seq", rows(seqres) > 0 ? seqres : J(1,3,.))
    st_matrix("__kp_brdate", rows(orig) > 0 ? orig : J(1,1,.))
    st_matrix("__kp_coef", coefs)
    akstat = .
    akcv = .
    if (doak) {
        akstat = kperrony_akstats(ye, Dse)
        akcv = kperrony_akcv(q, nb, (nb > 0 ? brml : J(0,1,0)), rows(Dse), sig, akreps, pmseed)
    }
    st_numscalar("__kp_ak", akstat)
    st_numscalar("__kp_akcv", akcv)
    st_matrix("__kp_hacse", hacse)
    st_matrix("__kp_stdse", stdse)
    st_matrix("__kp_dv", dvorig)
    st_matrix("__kp_ts", rows(tsres) > 0 ? tsres : J(1,3,.))
}

end
