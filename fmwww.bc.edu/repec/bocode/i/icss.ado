*! icss 1.0.0  22jul2026   (flexur library)
*! Iterated Cumulative Sum of Squares (ICSS) test for changes in the
*! unconditional variance of a time series -- with kurtosis- and
*! conditional-heteroskedasticity-robust statistics.
*!
*! Author : Dr Merwan Roudane  merwanroudane920@gmail.com
*!          https://github.com/merwanroudane
*! Part of the -flexur- library : flexible unit-root & stationarity tests.
*!
*! Faithful port of the GAUSS routines icss.src / variance.src by
*!   Andreu Sansó, Vicent Aragó & Josep Lluís Carrion-i-Silvestre.
*!   -- for public non-commercial use only.
*!
*! Reference:
*!   Sansó, A., Aragó, V., Carrion-i-Silvestre, J.L. (2004). Testing for
*!     changes in the unconditional variance of financial time series.
*!     Revista de Economía Financiera 4: 32-53.
*!   Inclán, C., Tiao, G.C. (1994). Use of cumulative sums of squares for
*!     retrospective detection of changes of variance. JASA 89: 913-923.
*!     <doi:10.1080/01621459.1994.10476824>
*!
*! Step -> equation map (see -help icss methods-):
*!   IT  statistic .... Inclán-Tiao (1994) eq.(1)          -> _icss_stat(test=0)
*!   kappa1 statistic . Sansó et al. Prop.2                -> _icss_stat(test=1)
*!   kappa2 statistic . Sansó et al. Prop.3 (LR 4th mom.)  -> _icss_stat(test=2)
*!   LR 4th moment .... omega4-hat, Bartlett/QS, NW(1994)  -> _icss_lvar
*!   5% critical value  response surface, Table 2          -> _icss_cv
*!   ICSS algorithm ... Inclán-Tiao / Sansó Section 5      -> _icss_icss

program icss, rclass
    version 14.0

    syntax varname(numeric ts) [if] [in] [ ,           ///
        Test(string)                                    ///
        Kernel(string)                                  ///
        Bwidth(real -1)                                 ///
        Binit(real 4)                                   ///
        noDEMEAN                                        ///
        ALL                                             ///
        Graph                                           ///
        GNAME(string)                                   ///
        GRAPHopts(string asis)                          ///
    ]

    marksample touse
    _icss_check_tsset
    local tvar  `s(tvar)'
    local tfmt  `s(tfmt)'

    quietly count if `touse'
    local T = r(N)
    if `T' < 15 {
        di as error "icss: need at least 15 usable observations (found `T')."
        exit 2001
    }

    * ----- resolve options ---------------------------------------------------
    if "`all'" != "" {
        local testlist "0 1 2"
    }
    else {
        if "`test'" == "" local test "k2"
        local test = lower("`test'")
        if      "`test'" == "it"               local testlist "0"
        else if inlist("`test'","k1","kappa1") local testlist "1"
        else if inlist("`test'","k2","kappa2") local testlist "2"
        else if "`test'" == "all"              local testlist "0 1 2"
        else {
            di as error "icss: test() must be it, k1, k2, or all."
            exit 198
        }
    }

    if "`kernel'" == "" local kernel "qs"
    local kernel = lower("`kernel'")
    if      inlist("`kernel'","qs","quadratic") local kcode 1
    else if inlist("`kernel'","bartlett","bt")  local kcode 0
    else {
        di as error "icss: kernel() must be bartlett or qs."
        exit 198
    }

    if `bwidth' >= 0 {
        local autoflag 0
        local manualbw `bwidth'
    }
    else {
        local autoflag 1
        local manualbw 0
    }

    local demeanflag 1
    if "`demean'" != "" local demeanflag 0

    * ----- header ------------------------------------------------------------
    di ""
    di as text "Iterated Cumulative Sum of Squares (ICSS) variance-break test"
    di as text "Sansó, Aragó & Carrion-i-Silvestre (2004)"
    di as text "{hline 64}"
    di as text "Series" _col(12) ": " as result "`varlist'" ///
        as text _col(40) "Obs (T)" _col(50) "= " as result %6.0f `T'
    local kdesc = cond(`kcode'==1,"Quadratic spectral","Bartlett")
    local bwdesc = cond(`autoflag'==1,"automatic (Newey-West 1994)","manual")
    di as text "Kernel" _col(12) ": " as result "`kdesc'" ///
        as text _col(40) "Bandwidth" _col(50) "= " as result "`bwdesc'"
    di as text "{hline 64}"

    tempname CP SEGS BRK BDATE
    local anybreaks 0
    local nb 0

    * ----- loop over requested tests -----------------------------------------
    foreach tc of local testlist {

        mata: _icss_run("`varlist'", "`tvar'", "`touse'", `tc', `kcode', `autoflag', `binit', `manualbw', `demeanflag')

        local nb = r(nbreaks)

        local labtc = cond(`tc'==0,"IT (Inclán-Tiao)", ///
                       cond(`tc'==1,"kappa1 (kurtosis-robust)", ///
                                    "kappa2 (kurtosis & cond. heterosk. robust)"))

        di as text ""
        di as text "Test: " as result "`labtc'"
        di as text "{hline 64}"
        di as text "  Whole-sample statistic" _col(42) "= " as result %9.4f r(stat)
        di as text "  5% critical value (resp. surface)" _col(42) "= " as result %9.4f r(cv5)
        di as text "  Asymptotic p-value" _col(42) "= " as result %9.4f r(pvalue)
        if `tc'==2 & `autoflag'==1 {
            di as text "  Long-run bandwidth used" _col(42) "= " as result %9.3f r(bandwidth)
        }
        local star = cond(r(pvalue)<0.01,"***",cond(r(pvalue)<0.05,"**",cond(r(pvalue)<0.10,"*","")))
        di as text "  Reject constant variance (whole sample)? " ///
            as result cond(r(stat)>r(cv5),"yes `star'","no")

        di as text ""
        di as text "  Detected changes in variance (ICSS) : " as result `nb'
        if `nb' > 0 {
            local anybreaks 1
            matrix `SEGS' = r(segs)
            matrix `BRK'  = r(breaks)
            capture matrix `BDATE' = r(breakdates)
            di as text "  {hline 60}"
            di as text "   #" _col(9) "Position" _col(22) "Date" _col(40) "Segment SD"
            di as text "  {hline 60}"
            forvalues b = 1/`nb' {
                local pos = `BRK'[`b',1]
                local sdb = `SEGS'[`b'+1,4]
                if "`tvar'" != "" & "`tfmt'" != "" {
                    local dv = `BDATE'[`b',1]
                    local ds : di `tfmt' `dv'
                }
                else local ds "`pos'"
                di as text "  " %3.0f `b' _col(9) as result %8.0f `pos' ///
                    _col(20) "`ds'" _col(40) %10.5f `sdb'
            }
            di as text "  {hline 60}"
            matrix `CP' = r(cp)
        }
        else {
            di as text "  (no change in unconditional variance detected)"
        }

        return scalar stat_`tc'    = r(stat)
        return scalar cv5_`tc'     = r(cv5)
        return scalar pval_`tc'    = r(pvalue)
        return scalar nbreaks_`tc' = `nb'
    }

    di as text "{hline 64}"
    di as text "Note: asymptotic p-value from the sup|Brownian bridge| distribution;"
    di as text "      ICSS break detection uses the 5% response-surface critical value."
    di as text "      *** p<.01, ** p<.05, * p<.10."

    * ----- returns (last test in list) ---------------------------------------
    return scalar T       = `T'
    return scalar nbreaks = `nb'
    return local  tests   "`testlist'"
    return local  kernel  "`kdesc'"
    return local  cmd     "icss"
    if `nb' > 0 {
        return matrix breaks = `BRK'
        return matrix segs   = `SEGS'
    }

    * ----- plot --------------------------------------------------------------
    if "`graph'" != "" {
        if `anybreaks' == 0 {
            di as text "icss: no breaks to plot."
        }
        else {
            _icss_plot `varlist' if `touse', tvar(`tvar') cp(`CP') ///
                demean(`demeanflag') gname(`gname') `graphopts'
        }
    }
end


* -------------------------------------------------------------------------
* helper: read tsset settings without erroring on non-tsset data
* -------------------------------------------------------------------------
program _icss_check_tsset, sclass
    sreturn clear
    capture tsset
    if _rc == 0 {
        sreturn local tvar "`r(timevar)'"
        if "`r(timevar)'" != "" {
            local f : format `r(timevar)'
            sreturn local tfmt "`f'"
        }
    }
end


* -------------------------------------------------------------------------
* helper: journal-style break plot (built from result matrices)
* -------------------------------------------------------------------------
program _icss_plot
    syntax varname [if] [in], CP(name) [ TVAR(string) DEMEAN(integer 1) ///
        GNAME(string) * ]
    marksample touse
    preserve
    quietly keep if `touse'
    tempvar xax
    if "`tvar'" != "" {
        quietly gen double `xax' = `tvar'
        local xt "`tvar'"
    }
    else {
        quietly gen double `xax' = _n
        local xt "obs"
    }
    tempvar y2
    quietly summarize `varlist', meanonly
    if `demean' {
        quietly gen double `y2' = (`varlist' - r(mean))^2
    }
    else {
        quietly gen double `y2' = `varlist'^2
    }

    tempvar segv sq
    quietly gen double `sq' = `y2'
    quietly gen double `segv' = .
    local nrow = rowsof(`cp')
    quietly gen long _icssn = _n
    forvalues s = 1/`=`nrow'-1' {
        local a = `cp'[`s',1]
        local b = `cp'[`s'+1,1]
        if `s' > 1 local a = `a' + 1
        quietly summarize `sq' if inrange(_icssn,`a',`b'), meanonly
        quietly replace `segv' = r(mean) if inrange(_icssn,`a',`b')
    }
    drop _icssn

    local xlines ""
    forvalues s = 2/`=`nrow'-1' {
        local p = `cp'[`s',1]
        local xv = `xax'[`p']
        local xlines "`xlines' `xv'"
    }

    local gn ""
    if "`gname'" != "" local gn name(`gname', replace)

    local xlopt ""
    if "`xlines'" != "" local xlopt xline(`xlines', lpattern(dash) lcolor(cranberry))

    twoway (line `y2' `xax', lcolor(gs11) lwidth(vthin))                     ///
           (line `segv' `xax', connect(J) lcolor(navy) lwidth(medthick)) ,   ///
        `xlopt'                                                             ///
        legend(order(1 "Squared series" 2 "ICSS segment variance") rows(1)) ///
        ytitle("Squared deviations / variance") xtitle("`xt'")              ///
        title("ICSS: changes in unconditional variance")                   ///
        graphregion(color(white)) plotregion(color(white)) `gn' `options'
    restore
end


* =========================================================================
* Mata engine  (single-line signatures; no /// inside mata)
* =========================================================================
version 14.0
mata:

real colvector _icss_autocov(real colvector e)
{
    real scalar t, j
    real colvector em, acov
    t = rows(e)
    em = e :- mean(e)
    acov = J(t,1,0)
    j = 0
    while (j <= t-1) {
        acov[j+1] = cross(em[(1+j)::t], em[1::(t-j)]) / t
        j = j + 1
    }
    return(acov)
}

real colvector _icss_bartlett(real scalar t, real scalar m)
{
    real colvector j, kern
    j = (0::t-1)
    kern = 1 :- j/(m+1)
    kern = kern :* (kern :> 0)
    return(kern)
}

real colvector _icss_qs(real scalar t, real scalar m)
{
    real colvector j, kern
    if (m > 0) {
        j = (1::t-1) / m
        kern = (25 :/ (12 * pi()^2 * j:^2)) :* (sin(1.2*pi()*j) :/ (1.2*pi()*j) :- cos(1.2*pi()*j))
        kern = 1 \ kern
    }
    else kern = 1 \ J(t-1,1,0)
    return(kern)
}

real scalar _icss_lagsel(real scalar kerntype, real colvector acov, real scalar n, real scalar T)
{
    real scalar s0, s1, s2, gam, m
    real colvector j
    if (n > 0) {
        j = J(n+1,1,2); j[1] = 1
        s0 = cross(j, acov[1::n+1])
        if (kerntype == 0) {
            j = 2 * (0::n)
            s1 = cross(j, acov[1::n+1])
            gam = 1.1447 * ((s1/s0)^2)^(1/3)
            m = min((T, trunc(gam * T^(1/3))))
        }
        else {
            j = 2 * ((0::n):^2)
            s2 = cross(j, acov[1::n+1])
            gam = 1.3221 * ((s2/s0)^2)^(1/5)
            m = min((T, gam * T^(1/5)))
        }
    }
    else m = 0
    return(m)
}

real rowvector _icss_lvar(real colvector x, real scalar kernel, real scalar autoflag, real scalar binit, real scalar manualbw)
{
    real scalar t, m, n, lr
    real colvector acov, kern, k
    t = rows(x)
    acov = _icss_autocov(x)
    if (autoflag == 0) m = manualbw
    else {
        if (kernel == 0) n = trunc(binit * (t/100)^(2/9))
        else             n = trunc(binit * (t/100)^(2/25))
        if (n < 0) n = 0
        if (rows(acov) < n+1) m = rows(acov)
        else m = _icss_lagsel(kernel, acov, n, t)
    }
    if (kernel == 0) kern = _icss_bartlett(t, m)
    else             kern = _icss_qs(t, m)
    k = J(t,1,2); k[1] = 1
    lr = sum(k :* acov :* kern)
    return((lr, m))
}

real rowvector _icss_stat(real colvector e, real scalar test, real scalar kernel, real scalar autoflag, real scalar binit, real scalar manualbw)
{
    real scalar t, Ctot, s2, c, m, tb, bw, a4
    real colvector csum, dk, e2, idx
    real matrix w
    real rowvector lv
    t = rows(e)
    csum = runningsum(e:^2)
    Ctot = csum[t]
    bw = .
    if (test == 0) {
        dk = abs(csum/Ctot :- (1::t)/t)
        maxindex(dk, 1, idx, w); tb = idx[1]
        m = sqrt(t/2) * dk[tb]
    }
    else {
        s2 = Ctot/t
        dk = abs(csum :- (1::t)*s2)
        if (test == 1) {
            a4 = sum(e:^4)/t
            c = sqrt(a4 - s2^2)
        }
        else {
            e2 = e:^2 :- s2
            lv = _icss_lvar(e2, kernel, autoflag, binit, manualbw)
            c = sqrt(lv[1])
            bw = lv[2]
        }
        maxindex(dk, 1, idx, w)
        tb = idx[1]
        m = sqrt(1/t) * dk[tb] / c
    }
    return((m, tb, bw))
}

real scalar _icss_cv(real scalar test, real scalar T)
{
    real scalar cv
    if (test == 0) cv = 1.35916702161 - 0.691555872065/T - 0.737020411768/sqrt(T)
    else if (test == 1) cv = 1.36393394011 + 0.500405392256/T - 0.942936124935/sqrt(T)
    else cv = 0.376035908994 - 3882905.1062/T^4 + 350603.023145/T^3 - 605.377401312/T^(2/3) - 16685.0174926/T^2 + 184.011220614/sqrt(T) + 1194.76624277/T + 16485653.7171/T^5
    return(cv)
}

real scalar _icss_pval(real scalar x)
{
    real scalar s, j
    if (x <= 0) return(1)
    s = 0
    j = 1
    while (j <= 200) {
        s = s + 2*(-1)^(j+1)*exp(-2*j^2*x^2)
        j = j + 1
    }
    if (s < 0) s = 0
    if (s > 1) s = 1
    return(s)
}

real rowvector _icss_selec(real colvector e, real scalar t1, real scalar t2, real scalar test, real scalar kernel, real scalar autoflag, real scalar binit, real scalar manualbw)
{
    real colvector aa
    real rowvector s
    real scalar m1, cv, tb1, pos, tb, senyal
    aa = e[t1::t2]
    s = _icss_stat(aa, test, kernel, autoflag, binit, manualbw)
    m1 = s[1]; tb1 = s[2]
    cv = _icss_cv(test, rows(aa))
    if (m1 > cv) {
        pos = tb1 + t1 - 1
        if (pos == t1) {
            tb = t1
            senyal = 0
        }
        else if (pos == t2) {
            tb = t2
            senyal = 1
        }
        else {
            tb = pos
            senyal = 2
        }
    }
    else {
        tb = -1
        senyal = 3
    }
    return((m1, cv, tb, senyal))
}

real rowvector _icss_bypass(real colvector e, real scalar t1i, real scalar t2i, real scalar test, real scalar kernel, real scalar autoflag, real scalar binit, real scalar manualbw)
{
    real scalar t1, t2, tbprev, tb, senyal
    real rowvector r
    t1 = t1i
    t2 = t2i
    tbprev = 0
    while (1) {
        r = _icss_selec(e, t1, t2, test, kernel, autoflag, binit, manualbw)
        tb = r[3]
        senyal = r[4]
        if (senyal == 2) {
            t2 = tb
            tbprev = tb
        }
        else if (senyal == 1) {
            t2 = tb
            break
        }
        else if (senyal == 3) {
            if (tbprev != 0) t2 = tbprev
            else t2 = 0
            break
        }
        else break
    }
    return((t1, t2, tbprev))
}

real matrix _icss_nbrseq(real colvector e, real scalar test, real scalar kernel, real scalar autoflag, real scalar binit, real scalar manualbw)
{
    real matrix cp
    real scalar i, j, tini, tfin, t2, restart
    real rowvector b
    i = 0
    cp = (0,0) \ (rows(e),0)
    restart = 1
    while (restart) {
        restart = 0
        cp = sort(cp,1)
        j = 1
        while (j <= rows(cp)-1) {
            tini = cp[j,1]+1
            tfin = cp[j+1,1]
            b = _icss_bypass(e, tini, tfin, test, kernel, autoflag, binit, manualbw)
            t2 = b[2]
            if (t2 != 0 & t2 != tfin) {
                i = i + 1
                cp = cp \ (t2,i)
                restart = 1
                break
            }
            else if (t2 != 0 & t2 == tfin) {
                return(sort(cp,1))
            }
            j = j + 1
        }
    }
    return(sort(cp,1))
}

real matrix _icss_nbreaks(real colvector e, real scalar test, real scalar kernel, real scalar autoflag, real scalar binit, real scalar manualbw)
{
    real matrix cpit, cp, indt, temp
    real scalar i, t1, t2, kf, kl, restart
    i = 0
    cpit = (1,0) \ (rows(e),0)
    restart = 1
    while (restart) {
        restart = 0
        cpit = sort(cpit,1)
        indt = select(cpit, cpit[,2]:==i)
        t1 = min(indt[,1]); t2 = max(indt[,1])
        cp = _icss_nbrseq(e[t1::t2], test, kernel, autoflag, binit, manualbw)
        temp = select(cp, cp[,2]:!=0)
        if (rows(temp) > 0) {
            kf = min(temp[,1]) + t1 - 1
            kl = max(temp[,1]) + t1 - 1
            if (kf == kl | abs(kl-kf) < 2) {
                i = i + 1
                cpit = cpit \ (kf,i)
            }
            else if (abs(kl-kf) > 2) {
                i = i + 1
                cpit = cpit \ ((kf,i)\(kl,i))
                restart = 1
            }
        }
    }
    return(sort(cpit,1))
}

real colvector _icss_icss(real colvector e, real scalar test, real scalar kernel, real scalar autoflag, real scalar binit, real scalar manualbw)
{
    real matrix cpm
    real colvector cp, cpi
    real scalar imax, j, tini, tfin, t2, restart, conv
    real rowvector b
    cpm = _icss_nbreaks(e, test, kernel, autoflag, binit, manualbw)
    cp = cpm[,1]
    imax = 1; cpi = cp
    restart = 1
    while (restart) {
        restart = 0
        cp = sort(cp,1)
        j = 1
        while (j <= rows(cp)-2) {
            tini = cp[j]+1
            tfin = cp[j+2]
            b = _icss_bypass(e, tini, tfin, test, kernel, autoflag, binit, manualbw)
            t2 = b[2]
            if (t2 == 0) cpi = select(cpi, cpi:!=cp[j+1])
            j = j + 1
        }
        if (rows(cpi) < rows(cp)) {
            imax = imax + 1
            if (imax < 20) {
                cp = cpi
                restart = 1
            }
        }
        else {
            conv = 1
            j = 1
            while (j <= rows(cp)) {
                if (abs(cp[j]-cpi[j]) > 2) {
                    conv = 0
                    break
                }
                j = j + 1
            }
            if (!conv) {
                imax = imax + 1
                cp = cpi
                if (imax <= 20) restart = 1
            }
            else cp = cpi
        }
    }
    return(sort(cpi,1))
}

void _icss_run(string scalar vname, string scalar tname, string scalar touse, real scalar test, real scalar kernel, real scalar autoflag, real scalar binit, real scalar manualbw, real scalar demean)
{
    real colvector e, tvals, cp, brks, bdates
    real rowvector s
    real matrix segs
    real scalar T, mstat, cv5, pval, bw, nb, i, a, bnd, v

    e = st_data(., vname, touse)
    if (demean) e = e :- mean(e)
    T = rows(e)
    if (tname != "") tvals = st_data(., tname, touse)
    else             tvals = (1::T)

    s = _icss_stat(e, test, kernel, autoflag, binit, manualbw)
    mstat = s[1]; bw = s[3]
    cv5 = _icss_cv(test, T)
    pval = _icss_pval(mstat)

    cp = _icss_icss(e, test, kernel, autoflag, binit, manualbw)
    nb = rows(cp) - 2

    segs = J(rows(cp)-1, 4, .)
    i = 1
    while (i <= rows(cp)-1) {
        a   = cp[i]
        bnd = cp[i+1]
        if (i > 1) a = a + 1
        v = mean(e[a::bnd]:^2)
        segs[i,1] = a
        segs[i,2] = bnd
        segs[i,3] = v
        segs[i,4] = sqrt(v)
        i = i + 1
    }

    st_numscalar("r(stat)", mstat)
    st_numscalar("r(cv5)", cv5)
    st_numscalar("r(pvalue)", pval)
    st_numscalar("r(bandwidth)", bw)
    st_numscalar("r(nbreaks)", nb)
    st_matrix("r(cp)", cp)
    st_matrix("r(segs)", segs)
    if (nb > 0) {
        brks = cp[2::rows(cp)-1]
        bdates = tvals[brks]
        st_matrix("r(breaks)", brks)
        st_matrix("r(breakdates)", bdates)
    }
}

end
