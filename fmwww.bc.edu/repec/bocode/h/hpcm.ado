*! hpcm 1.0.0  11jul2026
*! Hosoya (2001) partial measures of causality by one-way-effect elimination
*! Journal of Time Series Analysis 22(5), 537-554 <doi:10.1111/1467-9892.00243>
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*! GitHub: https://github.com/merwanroudane
*!
*! Step -> equation map (full derivation in help hpcm methods):
*!   VAR(p) fit of w=(x,y,z)           -> A(L)w=e,  Cov(e)=Sy   (Sec 5, eq 5.5)
*!   one-way effect z0,0,-1 = P e      -> P=[-Sy_3o Sy_oo^-1, I] (Sec 2 & 4)
*!   remove z-one-way effect from x,y  -> g(l)=(1/2pi) Psi_o M Sy Psi_o'  (eq 4.2)
*!   canonical factor of g via long-VAR-> Gamma(0)Gamma(e^-il)^-1 = B(e^-il)
*!   one-way measures PM(y->x:z),..    -> eq (4.4),(4.5)
*!   association PM(x,y:z)             -> eq (4.6)
*!   reciprocity PM(x:y:z)            -> Theorem 4.2 identity (eq 4.8)
*!   overall = (1/2pi) int PM(l) dl    -> Theorem 3.1 / 4.1
*!   Wald inference on band measures   -> Section 6, chi2(m)

program define hpcm, rclass
    version 14.0

    * ---- parse command line ---------------------------------------------
    syntax anything(id="variables" equalok) [if] [in] [,           ///
             VAR(integer 0) MAXvar(integer 8) IC(string)            ///
             GRID(integer 300) MLag(integer 20) MATrunc(integer 1200) ///
             Band(numlist min=2 max=2) LEVel(cilevel)               ///
             Difference(integer 0) NODEcompose                       ///
             Plot NAME(string) NODraw                                ///
             Breps(integer 0) SEED(string) noWALD noHEADer ]

    * ---- parse the three (x)(y)(z) groups --------------------------------
    _hpcm_groups `"`anything'"'
    local xg "`r(g1)'"
    local yg "`r(g2)'"
    local zg "`r(g3)'"
    unab xg : `xg'
    unab yg : `yg'
    unab zg : `zg'
    local p1 : word count `xg'
    local p2 : word count `yg'
    local p3 : word count `zg'
    local K  = `p1' + `p2' + `p3'
    local q  = `p1' + `p2'
    local wvars "`xg' `yg' `zg'"

    * check tsset
    capture quietly tsset
    if _rc | "`r(timevar)'"=="" {
        di as error "data must be {help tsset:tsset} (time series) before using hpcm"
        exit 459
    }
    local tvar "`r(timevar)'"
    local panelvar "`r(panelvar)'"
    if "`panelvar'"!="" {
        di as error "hpcm is a time-series command; data are xtset as a panel."
        di as error "Use it on a single time series (tsset time only)."
        exit 459
    }

    * ---- IC / band defaults ----------------------------------------------
    if "`ic'"=="" local ic "aic"
    if !inlist("`ic'","aic","bic","hqic","sbic") {
        di as error "ic() must be aic, bic (sbic) or hqic"
        exit 198
    }
    if "`ic'"=="sbic" local ic "bic"
    if "`band'"=="" local band "0 `=_pi'"
    tokenize `band'
    local blo `1'
    local bhi `2'
    if (`blo'<0 | `bhi'>_pi | `blo'>=`bhi') {
        di as error "band() must satisfy 0 <= lo < hi <= pi (= `=string(_pi,"%6.4f")')"
        exit 198
    }

    * ---- build the estimation sample -------------------------------------
    marksample touse, novarlist
    markout `touse' `wvars'
    * apply differencing (Section 5 reduction for I(1) series)
    tempvar dtag
    if (`difference'>0) {
        local dwvars ""
        foreach v of local wvars {
            tempvar d`v'
            quietly gen double `d`v'' = D`difference'.`v' if `touse'
            local dwvars "`dwvars' `d`v''"
        }
        local wvars "`dwvars'"
        markout `touse' `wvars'
    }
    quietly count if `touse'
    local N = r(N)
    if (`N' < `K'*(`=max(`var',2)') + 10) {
        di as error "too few usable observations (`N') for a `K'-variable VAR"
        exit 2001
    }

    * ---- pull the data into Mata (contiguous, time-ordered) ---------------
    * ensure a single contiguous time block over touse
    tempname WMAT
    mata: hpcm_getdata("`wvars'","`touse'","`tvar'")

    * ---- select VAR order by IC if var() not given -----------------------
    if (`var'<=0) {
        _hpcm_order, maxvar(`maxvar') ic(`ic')
        local var = r(popt)
    }
    if (`var'<1) local var 1

    * ---- run the engine ---------------------------------------------------
    local dowald = cond("`wald'"=="",1,0)
    mata: hpcm_run(`p1',`p2',`p3',`var',`grid',`blo',`bhi',`mlag',`matrunc', ///
                   `dowald', `breps', "`seed'")

    * r(...) scalars/matrices are posted by the Mata engine.  Retrieve for display.
    tempname OM CURVE WLD
    matrix `OM'    = r(overall)
    matrix `CURVE' = r(curve)
    if (`breps'>0) {
        tempname BCI
        matrix `BCI' = r(bootci)
    }
    if ("`wald'"=="") {
        matrix `WLD' = r(waldtab)
    }
    local varchosen = `var'
    local mused     = r(m)
    local stable    = r(stable)

    * ==================== display =========================================
    if ("`header'"=="") {
        di ""
        di as text "{hline 78}"
        di as text "Hosoya (2001) partial measures of causality (one-way-effect elimination)"
        di as text "{hline 78}"
        di as text "  x = {res}`xg'"
        di as text "  y = {res}`yg'"
        di as text "  z (conditioning) = {res}`zg'"
        di as text "  VAR order p = {res}`varchosen'{txt}   (selected by {res}`=upper("`ic'")'{txt})" ///
                   _col(46) "Obs = {res}`N'"
        di as text "  factorization VAR order m = {res}`mused'" ///
                   _col(46) "grid = {res}`grid'{txt} points on [0,pi]"
        if (`difference'>0) di as text "  series differenced d = {res}`difference'{txt} (Section 5 reduction)"
        di as text "  band = [{res}`=string(`blo',"%5.3f")'{txt}, {res}`=string(`bhi',"%5.3f")'{txt}] radians"
        if (`stable'==0) di as error "  WARNING: fitted VAR is not stable (a companion root is >= 1)."
    }

    * ---- table of overall partial measures --------------------------------
    * `OM' rows: 1=full-band, 2=chosen-band ; cols: yx xy recip assoc
    di ""
    di as text "  Overall partial measures  (Theorem 4.1; overall = 1/2pi * integral)"
    di as text "  {hline 66}"
    di as text %-34s "  Measure" %13s "full band" %13s "band"
    di as text "  {hline 66}"
    di as text %-34s "  PM(y -> x : z)  one-way y=>x" ///
        as result %13.6f `OM'[1,1] %13.6f `OM'[2,1]
    di as text %-34s "  PM(x -> y : z)  one-way x=>y" ///
        as result %13.6f `OM'[1,2] %13.6f `OM'[2,2]
    if ("`decompose'"=="") {
        di as text %-34s "  PM(x : y : z)   reciprocity" ///
            as result %13.6f `OM'[1,3] %13.6f `OM'[2,3]
        di as text %-34s "  PM(x , y : z)   association" ///
            as result %13.6f `OM'[1,4] %13.6f `OM'[2,4]
    }
    di as text "  {hline 66}"
    if ("`decompose'"=="") {
        di as text "  Decomposition (Thm 4.2): association = (x->y) + reciprocity + (y->x)"
    }

    * ---- Wald tests (Section 6) ------------------------------------------
    if ("`wald'"=="") {
        di ""
        di as text "  Wald tests of partial non-causality over the band (Section 6)"
        di as text "  {hline 66}"
        di as text %-34s "  Null hypothesis" %10s "chi2" %6s "df" %11s "p-value"
        di as text "  {hline 66}"
        forvalues i = 1/3 {
            if (`i'==1) local lab "H0: PM(y -> x : z) = 0"
            if (`i'==2) local lab "H0: PM(x -> y : z) = 0"
            if (`i'==3) local lab "H0: no partial causality"
            local pv = `WLD'[`i',3]
            local st ""
            if (`pv'<.10) local st "*"
            if (`pv'<.05) local st "**"
            if (`pv'<.01) local st "***"
            di as text %-34s "  `lab'" ///
                as result %10.3f `WLD'[`i',1] %6.0f `WLD'[`i',2] %11.4f `pv' ///
                as text " `st'"
        }
        di as text "  {hline 66}"
        di as text "  Stars: {res}* {txt}p<.10  {res}** {txt}p<.05  {res}*** {txt}p<.01"
        di as text "  Note: the null sits on the boundary (measure>=0); the chi2"
        di as text "  approximation is then conservative.  See {help hpcm methods}."
    }

    * ---- bootstrap CIs ----------------------------------------------------
    if (`breps'>0) {
        di ""
        di as text "  Parametric-bootstrap 95% CIs of band measures (`breps' reps)"
        di as text "  {hline 66}"
        di as text %-34s "  Measure" %13s "lower" %13s "upper"
        di as text "  {hline 66}"
        di as text %-34s "  PM(y -> x : z)" ///
            as result %13.6f `BCI'[1,1] %13.6f `BCI'[1,2]
        di as text %-34s "  PM(x -> y : z)" ///
            as result %13.6f `BCI'[2,1] %13.6f `BCI'[2,2]
        di as text "  {hline 66}"
    }

    * ==================== graphs ==========================================
    if ("`plot'"!="") {
        _hpcm_plot, curve(`CURVE') blo(`blo') bhi(`bhi') ///
            name(`name') `draw' `=cond("`decompose'"=="","","noassoc")'
    }

    * ==================== returns =========================================
    return scalar N      = `N'
    return scalar p      = `varchosen'
    return scalar m      = `mused'
    return scalar grid   = `grid'
    return scalar K      = `K'
    return scalar p1     = `p1'
    return scalar p2     = `p2'
    return scalar p3     = `p3'
    return scalar blo    = `blo'
    return scalar bhi    = `bhi'
    return scalar stable = `stable'
    return scalar PM_yx      = `OM'[1,1]
    return scalar PM_xy      = `OM'[1,2]
    return scalar PM_recip   = `OM'[1,3]
    return scalar PM_assoc   = `OM'[1,4]
    return scalar PM_yx_band = `OM'[2,1]
    return scalar PM_xy_band = `OM'[2,2]
    if ("`wald'"=="") {
        return scalar chi2_yx    = `WLD'[1,1]
        return scalar p_yx       = `WLD'[1,3]
        return scalar chi2_xy    = `WLD'[2,1]
        return scalar p_xy       = `WLD'[2,3]
        return scalar chi2_joint = `WLD'[3,1]
        return scalar p_joint    = `WLD'[3,3]
        return matrix wald = `WLD'
    }
    return local  ic     "`ic'"
    return local  tvar   "`tvar'"
    return local  xvars  "`xg'"
    return local  yvars  "`yg'"
    return local  zvars  "`zg'"
    return local  cmd    "hpcm"
    matrix colnames `OM' = PM_yx PM_xy PM_recip PM_assoc
    matrix rownames `OM' = full band
    return matrix overall = `OM'
    return matrix curve   = `CURVE'
end

* -----------------------------------------------------------------------
* parse the three groups (x)(y)(z) or three bare varlists into r(g1..g3)
* -----------------------------------------------------------------------
program define _hpcm_groups, rclass
    args spec
    local spec = trim(`"`spec'"')
    local i 0
    if (strpos(`"`spec'"',"(")>0) {
        * parenthesized-group form
        local rest `"`spec'"'
        while (`"`rest'"'!="" & `i'<3) {
            gettoken tok rest : rest, match(par) parse(" ()")
            if (`"`tok'"'=="") continue
            local ++i
            local g`i' `"`tok'"'
        }
    }
    else {
        * three bare variable names (p1=p2=p3=1)
        gettoken g1 rest : spec
        gettoken g2 rest : rest
        gettoken g3 rest : rest
        local i 3
        if (`"`g1'"'=="" | `"`g2'"'=="" | `"`g3'"'=="") local i 0
    }
    if (`i'<3) {
        di as error "specify three variable groups: hpcm (xvars) (yvars) (zvars)"
        di as error "  or three single series:      hpcm xvar yvar zvar"
        exit 198
    }
    return local g1 `"`g1'"'
    return local g2 `"`g2'"'
    return local g3 `"`g3'"'
end

* -----------------------------------------------------------------------
* VAR-order selection by information criterion (uses varsoc)
* -----------------------------------------------------------------------
program define _hpcm_order, rclass
    syntax , maxvar(integer) ic(string)
    * varsoc reads the Mata data we already have? no; refit quickly with varsoc
    * fall back: choose via Mata using the loaded data
    mata: hpcm_ordersel(`maxvar', "`ic'")
    return scalar popt = r(popt)
end

* -----------------------------------------------------------------------
* journal-style frequency plots
* -----------------------------------------------------------------------
program define _hpcm_plot
    syntax , curve(name) blo(real) bhi(real) [ name(string) noDraw noAssoc ]
    if ("`name'"=="") local name hpcm
    preserve
    quietly {
        clear
        set obs `=rowsof(`curve')'
        svmat double `curve', name(_c)
        * columns: 1=lambda 2=PMyx 3=PMxy 4=recip 5=assoc
        rename _c1 lambda
        rename _c2 pm_yx
        rename _c3 pm_xy
        rename _c4 pm_rec
        rename _c5 pm_ass
        gen freq = lambda/(2*_pi)
    }
    local sc "graphregion(color(white)) plotregion(color(white))"
    local blf = `blo'/(2*_pi)
    local bhf = `bhi'/(2*_pi)

    twoway (line pm_yx freq, lcolor(navy) lwidth(medthick)) ///
           (line pm_xy freq, lcolor(cranberry) lpattern(dash) lwidth(medthick)), ///
           `sc' name(`name'_dir, replace) nodraw ///
           title("Directional partial one-way effects", size(medsmall)) ///
           ytitle("partial measure") xtitle("frequency  {&omega}/2{&pi}  (cycles)") ///
           legend(order(1 "y {&rarr} x | z" 2 "x {&rarr} y | z") size(small) rows(1)) ///
           xline(`blf' `bhf', lpattern(dot) lcolor(gs10))

    if ("`assoc'"=="") {
        twoway (line pm_ass freq, lcolor(dkgreen) lwidth(medthick)) ///
               (line pm_rec freq, lcolor(orange) lpattern(dash) lwidth(medthick)), ///
               `sc' name(`name'_int, replace) nodraw ///
               title("Interdependence and reciprocity", size(medsmall)) ///
               ytitle("partial measure") xtitle("frequency  {&omega}/2{&pi}  (cycles)") ///
               legend(order(1 "association x,y | z" 2 "reciprocity x:y | z") size(small) rows(1))
        graph combine `name'_dir `name'_int, `sc' cols(1) name(`name', replace) `draw' ///
            title("Hosoya (2001) partial causal measures", size(medsmall))
    }
    else {
        graph combine `name'_dir, `sc' name(`name', replace) `draw'
    }
    restore
end

* =======================================================================
* Mata engine  (compiled at load; if this fails run  do hpcm.ado  to see
* the exact offending line).  Inside mata use // comments only.
* =======================================================================
version 14.0
mata:

// ---- struct holding a VAR fit ---------------------------------------
struct hpcm_v {
    real matrix A          // K x (K*p)
    real matrix Sigma      // K x K   innovation covariance
    real matrix ZZinv      // (K*p) x (K*p)  lag Gram inverse
    real scalar T          // usable observations T - p
}

// ---- load the (already tsset, time-ordered) data into an external ----
void hpcm_getdata(string scalar vars, string scalar touse, string scalar tvar)
{
    external real matrix hpcm_W
    hpcm_W = st_data(., tokens(vars), touse)
}

// ---- safe log-determinant of a (possibly complex Hermitian) matrix ---
real scalar hpcm_ld(matrix M)
{
    real scalar d
    d = Re(det(M))
    if (d < 1e-300) d = 1e-300
    return(ln(d))
}

// ---- fit a centered VAR(p) by OLS -----------------------------------
struct hpcm_v scalar hpcm_fit(real matrix W, real scalar p, real scalar t0)
{
    struct hpcm_v scalar v
    real matrix Wc, Y, Z, B, E, ZZ
    real scalar Tn, K, i, k, l, t, rr
    real colvector mu

    Tn = rows(W)
    K  = cols(W)
    // center on the common sample [t0+1 .. Tn]
    mu = (colsum(W[(t0+1)..Tn, .]) :/ (Tn - t0))'
    Wc = W :- mu'

    Y = Wc[(t0+1)..Tn, .]
    Z = J(Tn - t0, K*p, 0)
    for (t = t0+1; t <= Tn; t++) {
        for (k = 1; k <= p; k++) {
            for (l = 1; l <= K; l++) {
                Z[t-t0, (k-1)*K + l] = Wc[t-k, l]
            }
        }
    }
    ZZ = quadcross(Z, Z)
    v.ZZinv = luinv(ZZ)
    B = v.ZZinv * quadcross(Z, Y)          // (K*p) x K
    E = Y - Z*B
    v.T = rows(Y)
    v.Sigma = quadcross(E, E) / v.T
    // reshape B into A = [A_1 ... A_p], A_k[i,l] = B[(k-1)K+l, i]
    v.A = J(K, K*p, 0)
    for (k = 1; k <= p; k++) {
        for (i = 1; i <= K; i++) {
            for (l = 1; l <= K; l++) {
                v.A[i, (k-1)*K + l] = B[(k-1)*K + l, i]
            }
        }
    }
    return(v)
}

// ---- order selection by information criterion -----------------------
void hpcm_ordersel(real scalar maxv, string scalar ic)
{
    external real matrix hpcm_W
    struct hpcm_v scalar v
    real scalar pp, K, Tn, best, val, npar, popt, ldet
    real matrix W
    W = hpcm_W
    Tn = rows(W); K = cols(W)
    best = .; popt = 1
    for (pp = 1; pp <= maxv; pp++) {
        v = hpcm_fit(W, pp, maxv)          // common sample: drop first maxv rows
        ldet = hpcm_ld(v.Sigma)
        npar = K*K*pp
        if (ic == "aic")  val = ldet + 2*npar/v.T
        else if (ic=="bic") val = ldet + ln(v.T)*npar/v.T
        else                val = ldet + 2*ln(ln(v.T))*npar/v.T
        if (val < best) {
            best = val
            popt = pp
        }
    }
    st_numscalar("r(popt)", popt)
}

// ---- MA-annihilated innovation covariance  M*Sy  (eq 4.2 engine) -----
real matrix hpcm_msig(real matrix Sigma, real scalar p1, real scalar p2, real scalar p3)
{
    real scalar K, q
    real matrix Soo, So3, S3o, S33a, MSig
    real vector io, i3
    K = p1 + p2 + p3
    q = p1 + p2
    io = (1..q)
    i3 = ((q+1)..K)
    Soo = Sigma[io, io]
    So3 = Sigma[io, i3]
    S3o = Sigma[i3, io]
    S33a = Sigma[i3, i3] - S3o*luinv(Soo)*So3       // Schur complement  Sy_33.o
    // P (p3 x K): P[,io] = -S3o Soo^-1 , P[,i3] = I
    real matrix P
    P = J(p3, K, 0)
    P[., io] = -S3o*luinv(Soo)
    P[., i3] = I(p3)
    MSig = Sigma - Sigma*P'*luinv(S33a)*P*Sigma      // = M Sy , rank q
    MSig = (MSig + MSig')/2
    return(MSig)
}

// ---- MA coefficients Psi(0..n) of the VAR (companion recursion) ------
// returns stack (n+1)*K x K , block j = Psi(j)
real matrix hpcm_psi(real matrix A, real scalar K, real scalar p, real scalar n)
{
    real matrix Ps, S
    real scalar j, i
    Ps = J((n+1)*K, K, 0)
    Ps[1..K, .] = I(K)
    for (j = 1; j <= n; j++) {
        S = J(K, K, 0)
        for (i = 1; i <= min((j,p)); i++) {
            S = S + A[., (i-1)*K+1 .. i*K] * Ps[(j-i)*K+1 .. (j-i+1)*K, .]
        }
        Ps[j*K+1 .. (j+1)*K, .] = S
    }
    return(Ps)
}

// ---- autocovariances R(0..m) of (u,v) = Psi_o(L) M eps --------------
// returns q x ((m+1)q), block h = R(h)
real matrix hpcm_acov(real matrix A, real matrix MSig, real scalar K, real scalar p,
                      real scalar q, real scalar m, real scalar J)
{
    real matrix Ps, Rst, Rh, Poh, Poj, Bh, Bj
    real scalar h, j
    real vector io
    io = (1..q)
    // geometric decay for a stable VAR makes the truncation at J harmless
    Ps = hpcm_psi(A, K, p, J + m)
    Rst = J(q, (m+1)*q, 0)
    for (h = 0; h <= m; h++) {
        Rh = J(q, q, 0)
        for (j = 0; j <= J; j++) {
            Bh = Ps[(j+h)*K+1 .. (j+h+1)*K, .]
            Bj = Ps[j*K+1 .. (j+1)*K, .]
            Poh = Bh[io, .]                                 // Psi_o(j+h)  q x K
            Poj = Bj[io, .]                                 // Psi_o(j)    q x K
            Rh = Rh + Poh * MSig * Poj'
        }
        Rst[., h*q+1 .. (h+1)*q] = Rh
    }
    return(Rst)
}

// ---- multivariate Yule-Walker (long VAR) canonical factor -----------
// solves  Brow * Mbig = rvec ;  fills Bout (q x m*q) and Sout (q x q)
void hpcm_yw(real matrix Rst, real scalar q, real scalar m,
             real matrix Bout, real matrix Sout)
{
    real matrix Mbig, rvec, Brow, Rd
    real scalar k, jc, a, b
    Mbig = J(m*q, m*q, 0)
    for (k = 1; k <= m; k++) {
        for (jc = 1; jc <= m; jc++) {
            // block (k,jc) = R(jc-k) ; R(-h) = R(h)'
            a = jc - k
            if (a >= 0) Rd = Rst[., a*q+1 .. (a+1)*q]
            else        Rd = Rst[., (-a)*q+1 .. (-a+1)*q]'
            Mbig[(k-1)*q+1 .. k*q, (jc-1)*q+1 .. jc*q] = Rd
        }
    }
    rvec = J(q, m*q, 0)
    for (k = 1; k <= m; k++) {
        rvec[., (k-1)*q+1 .. k*q] = Rst[., k*q+1 .. (k+1)*q]
    }
    Brow = rvec * luinv(Mbig)                 // q x m*q  = [B_1 ... B_m]
    Bout = Brow
    Sout = Rst[., 1..q] - Brow*rvec'          // Sigma_uv = R(0) - Brow rvec'
    Sout = (Sout + Sout')/2
}

// ---- partial measures on a vector of frequencies --------------------
// returns rows(lam) x 5 : lambda, PM(y->x), PM(x->y), reciprocity, association
real matrix hpcm_worker(real matrix A, real matrix Sigma,
                        real scalar p1, real scalar p2, real scalar p3,
                        real scalar p, real colvector lam,
                        real scalar m, real scalar J)
{
    real scalar K, q, nl, gi, k, lamk, twopi
    real matrix MSig, Rst, Bcoef, Suv, out
    real matrix Saa, Sbb, Sab, Sba, Sba_a, Qb, Sig112, Qb2
    complex matrix Abar, Ainv, Aio, g, g11, g22, Bbar, tba, core, tuv, core2
    complex scalar im, ez
    real scalar dg11, dg22, dgg, pmyx, pmxy, pmass, pmrec
    real vector io, ix, iy

    K = p1 + p2 + p3
    q = p1 + p2
    twopi = 2*pi()
    io = (1..q)
    ix = (1..p1)
    iy = ((p1+1)..q)
    im = C(0,1)

    MSig  = hpcm_msig(Sigma, p1, p2, p3)
    Rst   = hpcm_acov(A, MSig, K, p, q, m, J)
    Bcoef = J(q, m*q, 0)
    Suv   = J(q, q, 0)
    hpcm_yw(Rst, q, m, Bcoef, Suv)

    // blocks of the (u,v) innovation covariance
    Saa = Suv[ix, ix]; Sbb = Suv[iy, iy]; Sab = Suv[ix, iy]; Sba = Suv[iy, ix]
    Sba_a  = Sbb - Sba*luinv(Saa)*Sab           // Sigma_22:1
    Sig112 = Saa - Sab*luinv(Sbb)*Sba           // Sigma_11:2
    Qb = J(p2, q, 0);  Qb[., ix] = -Sba*luinv(Saa);  Qb[., iy] = I(p2)
    Qb2 = J(p1, q, 0); Qb2[., ix] = I(p1);           Qb2[., iy] = -Sab*luinv(Sbb)

    nl = rows(lam)
    out = J(nl, 5, 0)
    for (gi = 1; gi <= nl; gi++) {
        lamk = lam[gi]
        // A(e^{-i lam})
        Abar = I(K)
        for (k = 1; k <= p; k++) {
            ez = exp(-im*k*lamk)
            Abar = Abar - A[., (k-1)*K+1 .. k*K] * ez
        }
        Ainv = luinv(Abar)
        Aio  = Ainv[io, .]                       // q x K
        g = (1/twopi) * Aio * MSig * Aio'        // q x q Hermitian
        g = (g + g')/2
        g11 = g[ix, ix]; g22 = g[iy, iy]
        dg11 = hpcm_ld(g11); dg22 = hpcm_ld(g22); dgg = hpcm_ld(g)

        // B(e^{-i lam}) = Gamma(0)Gamma(e^{-il})^{-1}
        Bbar = I(q)
        for (k = 1; k <= m; k++) {
            ez = exp(-im*k*lamk)
            Bbar = Bbar - Bcoef[., (k-1)*q+1 .. k*q] * ez
        }

        // PM(y->x:z) = M(v->u)   (receiver a = x-block, source b = y-block)
        tba  = Qb * Bbar * g[., ix]              // p2 x p1  = ~g21
        core = g11 - twopi * tba' * luinv(Sba_a) * tba
        pmyx = dg11 - hpcm_ld(core)
        if (pmyx < 0) pmyx = 0

        // PM(x->y:z) = M(u->v)
        tuv   = Qb2 * Bbar * g[., iy]            // p1 x p2
        core2 = g22 - twopi * tuv' * luinv(Sig112) * tuv
        pmxy = dg22 - hpcm_ld(core2)
        if (pmxy < 0) pmxy = 0

        // association (eq 4.6) and reciprocity (Thm 4.2)
        pmass = dg11 + dg22 - dgg
        if (pmass < 0) pmass = 0
        pmrec = pmass - pmyx - pmxy

        out[gi, 1] = lamk
        out[gi, 2] = pmyx
        out[gi, 3] = pmxy
        out[gi, 4] = pmrec
        out[gi, 5] = pmass
    }
    return(out)
}

// ---- trapezoidal integral of y over x -------------------------------
real scalar hpcm_trapz(real colvector x, real colvector y)
{
    real scalar s, i
    s = 0
    for (i = 2; i <= rows(x); i++) {
        s = s + 0.5*(x[i]-x[i-1])*(y[i]+y[i-1])
    }
    return(s)
}

// ---- overall (1/2pi int over [-pi,pi] = 1/pi int over [0,pi]) --------
// returns rowvector of the 4 measures integrated over [lo,hi]
real rowvector hpcm_integ(real matrix cv, real scalar lo, real scalar hi)
{
    real vector sel
    real matrix c
    real rowvector out
    real scalar j
    sel = selectindex((cv[.,1] :>= lo-1e-12) :& (cv[.,1] :<= hi+1e-12))
    c = cv[sel, .]
    out = J(1, 4, 0)
    for (j = 1; j <= 4; j++) {
        out[j] = (1/pi()) * hpcm_trapz(c[.,1], c[.,j+1])
    }
    return(out)
}

// ---- band measures as a function of (A,Sigma): used by the Jacobian --
real rowvector hpcm_bandmeas(real matrix A, real matrix Sigma,
                             real scalar p1, real scalar p2, real scalar p3,
                             real scalar p, real colvector lam,
                             real scalar lo, real scalar hi,
                             real scalar m, real scalar J)
{
    real matrix cv
    real rowvector oo
    cv = hpcm_worker(A, Sigma, p1, p2, p3, p, lam, m, J)
    oo = hpcm_integ(cv, lo, hi)
    return((oo[1], oo[2]))            // [PM(y->x), PM(x->y)] over the band
}

// ---- build the parameter covariance V (finite sample) ---------------
real matrix hpcm_vcov(struct hpcm_v scalar v, real scalar K, real scalar p)
{
    real scalar nA, nS, a, b, kk, ll, ii, kk2, ll2, ii2, rr, rr2
    real scalar s, s2, ir, jc, kr, lc, np
    real matrix V
    nA = K*K*p
    nS = K*(K+1)/2
    np = nA + nS
    V = J(np, np, 0)
    // A block : Cov(A_k[i,l], A_k2[i2,l2]) = Sigma[i,i2]*ZZinv[(k-1)K+l,(k2-1)K+l2]
    for (a = 1; a <= nA; a++) {
        kk = ceil(a/(K*K)); s = a - (kk-1)*K*K; ll = ceil(s/K); ii = s - (ll-1)*K
        rr = (kk-1)*K + ll
        for (b = 1; b <= nA; b++) {
            kk2 = ceil(b/(K*K)); s2 = b - (kk2-1)*K*K; ll2 = ceil(s2/K); ii2 = s2 - (ll2-1)*K
            rr2 = (kk2-1)*K + ll2
            V[a,b] = v.Sigma[ii,ii2]*v.ZZinv[rr,rr2]
        }
    }
    // Sigma block : Cov(s_ij,s_kl) = (1/T)(Sy_ik Sy_jl + Sy_il Sy_jk)
    // vech order: for jc=1..K, ir=jc..K
    real vector vr, vc
    vr = J(nS,1,0); vc = J(nS,1,0)
    s = 0
    for (jc = 1; jc <= K; jc++) {
        for (ir = jc; ir <= K; ir++) {
            s++
            vr[s] = ir; vc[s] = jc
        }
    }
    for (a = 1; a <= nS; a++) {
        ir = vr[a]; jc = vc[a]
        for (b = 1; b <= nS; b++) {
            kr = vr[b]; lc = vc[b]
            V[nA+a, nA+b] = (1/v.T)*(v.Sigma[ir,kr]*v.Sigma[jc,lc] + v.Sigma[ir,lc]*v.Sigma[jc,kr])
        }
    }
    return(V)
}

// ---- rebuild (A,Sigma) from a perturbed flat parameter vector -------
void hpcm_unpack(real vector th, real scalar K, real scalar p,
                 real matrix A, real matrix Sigma)
{
    real scalar nA, kk, ll, ii, s, jc, ir, cnt
    nA = K*K*p
    A = J(K, K*p, 0)
    for (s = 1; s <= nA; s++) {
        kk = ceil(s/(K*K)); cnt = s - (kk-1)*K*K; ll = ceil(cnt/K); ii = cnt - (ll-1)*K
        A[ii, (kk-1)*K + ll] = th[s]
    }
    Sigma = J(K, K, 0)
    cnt = nA
    for (jc = 1; jc <= K; jc++) {
        for (ir = jc; ir <= K; ir++) {
            cnt++
            Sigma[ir,jc] = th[cnt]
            Sigma[jc,ir] = th[cnt]
        }
    }
}

// ---- flatten (A,Sigma) into the same parameter vector ---------------
real colvector hpcm_pack(real matrix A, real matrix Sigma, real scalar K, real scalar p)
{
    real scalar nA, nS, kk, ll, ii, s, jc, ir, cnt
    real colvector th
    nA = K*K*p; nS = K*(K+1)/2
    th = J(nA+nS, 1, 0)
    for (s = 1; s <= nA; s++) {
        kk = ceil(s/(K*K)); cnt = s - (kk-1)*K*K; ll = ceil(cnt/K); ii = cnt - (ll-1)*K
        th[s] = A[ii, (kk-1)*K + ll]
    }
    cnt = nA
    for (jc = 1; jc <= K; jc++) {
        for (ir = jc; ir <= K; ir++) {
            cnt++
            th[cnt] = Sigma[ir,jc]
        }
    }
    return(th)
}

// ---- companion stability check --------------------------------------
real scalar hpcm_stable(real matrix A, real scalar K, real scalar p)
{
    real matrix Comp
    real scalar mx
    complex vector ev
    if (p == 1) {
        Comp = A
    }
    else {
        Comp = J(K*p, K*p, 0)
        Comp[1..K, .] = A
        Comp[K+1 .. K*p, 1 .. K*(p-1)] = I(K*(p-1))
    }
    ev = eigenvalues(Comp)
    mx = max(abs(ev))
    if (mx < 1) return(1)
    return(0)
}

// ---- main driver ----------------------------------------------------
void hpcm_run(real scalar p1, real scalar p2, real scalar p3, real scalar p,
              real scalar ng, real scalar blo, real scalar bhi,
              real scalar m, real scalar J, real scalar dowald,
              real scalar breps, string scalar seed)
{
    external real matrix hpcm_W
    struct hpcm_v scalar v, vb
    real matrix W, cv, V, Jac, H, Wtab, bootci, OM, Ap, Sp, Hi
    real matrix Ch, Wsim, draws
    real scalar K, q, i, hstep, dh, r, Tsim, tt, kk, qlo, qhi
    real colvector lam, th, Gp, Gm, G0, keep, tp, tm, d1, d2
    real rowvector ofull, oband, gb, pred

    W = hpcm_W
    K = p1 + p2 + p3
    q = p1 + p2

    v = hpcm_fit(W, p, p)                 // fit at chosen order (sample drops first p)

    // frequency grid on [0,pi], augmented with the band endpoints
    lam = (0::(ng-1)) :/ (ng-1) :* pi()
    lam = sort((lam \ blo \ bhi), 1)
    keep = J(rows(lam), 1, 1)
    for (i = 2; i <= rows(lam); i++) {
        if (abs(lam[i]-lam[i-1]) < 1e-12) keep[i] = 0
    }
    lam = select(lam, keep)

    cv = hpcm_worker(v.A, v.Sigma, p1, p2, p3, p, lam, m, J)

    ofull = hpcm_integ(cv, 0, pi())
    oband = hpcm_integ(cv, blo, bhi)
    OM = (ofull \ oband)

    st_matrix("r(overall)", OM)
    st_matrix("r(curve)", cv)
    st_numscalar("r(m)", m)
    st_numscalar("r(stable)", hpcm_stable(v.A, K, p))

    // ---------------- Wald inference (Section 6) --------------------
    if (dowald == 1) {
        th = hpcm_pack(v.A, v.Sigma, K, p)
        G0 = hpcm_bandmeas(v.A, v.Sigma, p1, p2, p3, p, lam, blo, bhi, m, J)'
        V  = hpcm_vcov(v, K, p)
        Jac = J(2, rows(th), 0)
        for (i = 1; i <= rows(th); i++) {
            hstep = 1e-4*(1 + abs(th[i]))
            tp = th; tm = th
            tp[i] = tp[i] + hstep
            tm[i] = tm[i] - hstep
            hpcm_unpack(tp, K, p, Ap, Sp)
            Gp = hpcm_bandmeas(Ap, Sp, p1, p2, p3, p, lam, blo, bhi, m, J)'
            hpcm_unpack(tm, K, p, Ap, Sp)
            Gm = hpcm_bandmeas(Ap, Sp, p1, p2, p3, p, lam, blo, bhi, m, J)'
            Jac[., i] = (Gp - Gm) / (2*hstep)
        }
        H = Jac * V * Jac'
        Wtab = J(3, 3, .)
        if (H[1,1] > 0) {
            Wtab[1,1] = G0[1]^2 / H[1,1]; Wtab[1,2] = 1
            Wtab[1,3] = chi2tail(1, Wtab[1,1])
        }
        else {
            Wtab[1,1] = 0; Wtab[1,2] = 1; Wtab[1,3] = 1
        }
        if (H[2,2] > 0) {
            Wtab[2,1] = G0[2]^2 / H[2,2]; Wtab[2,2] = 1
            Wtab[2,3] = chi2tail(1, Wtab[2,1])
        }
        else {
            Wtab[2,1] = 0; Wtab[2,2] = 1; Wtab[2,3] = 1
        }
        dh = Re(det(H))
        if (dh > 1e-18) {
            Hi = luinv(H)
            Wtab[3,1] = (G0' * Hi * G0); Wtab[3,2] = 2
            Wtab[3,3] = chi2tail(2, Wtab[3,1])
        }
        else {
            Wtab[3,1] = Wtab[1,1] + Wtab[2,1]; Wtab[3,2] = 2
            Wtab[3,3] = chi2tail(2, Wtab[3,1])
        }
        st_matrix("r(waldtab)", Wtab)
    }

    // ---------------- parametric bootstrap CIs ----------------------
    if (breps > 0) {
        if (seed != "") rseed(strtoreal(seed))
        Ch = cholesky(v.Sigma)
        Tsim = rows(W)
        draws = J(breps, 2, .)
        for (r = 1; r <= breps; r++) {
            Wsim = J(Tsim, K, 0)
            for (tt = p+1; tt <= Tsim; tt++) {
                pred = J(1, K, 0)
                for (kk = 1; kk <= p; kk++) {
                    pred = pred + (v.A[., (kk-1)*K+1 .. kk*K] * Wsim[tt-kk, .]')'
                }
                Wsim[tt, .] = pred + (Ch*rnormal(K, 1, 0, 1))'
            }
            Wsim = Wsim[(p+1)..Tsim, .]
            vb = hpcm_fit(Wsim, p, p)
            gb = hpcm_bandmeas(vb.A, vb.Sigma, p1, p2, p3, p, lam, blo, bhi, m, J)
            draws[r, .] = gb
        }
        bootci = J(2, 2, .)
        d1 = sort(draws[., 1], 1); d2 = sort(draws[., 2], 1)
        qlo = 0.025; qhi = 0.975
        bootci[1,1] = d1[max((1, round(qlo*breps)))]
        bootci[1,2] = d1[min((breps, round(qhi*breps)))]
        bootci[2,1] = d2[max((1, round(qlo*breps)))]
        bootci[2,2] = d2[min((breps, round(qhi*breps)))]
        st_matrix("r(bootci)", bootci)
    }
}

end

