*! xtcombreak_example.do  -- self-test / validation harness
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! GitHub: https://github.com/merwanroudane
*!
*! Runs every code path of xtcombreak against KNOWN TRUTH, using the two
*! papers' own Monte Carlo designs, and prints truth-vs-estimate so the log
*! can be refereed.
*!
*!   Part 1  Bai (2010) sec.3 DGP     -> does khat recover k0 as N grows?
*!   Part 2  Bai (2010) p.83 CI DGP   -> is the CI coverage near nominal?
*!   Part 3  Bai QML / GLS / variance breaks / multiple breaks / Chow
*!   Part 4  JK (2026) DGP.1 (null)   -> SIZE of the test
*!   Part 5  JK (2026) DGP.2 (H1A)    -> POWER of the test
*!   Part 6  ** CRITICAL ** simulated critical values vs JK Table 1
*!   Part 7  graphs + xtcombreak all
*!
*! Run with:   do xtcombreak.ado          (surfaces any Mata compile error)
*!             do xtcombreak_example.do

clear
set more off
version 14.0

/* NOTE: `clear', NOT `clear all' -- clear all would drop xtcombreak.ado
   if it was just loaded with `do xtcombreak.ado'. */

di as text _n(2) "{hline 79}"
di as text "xtcombreak validation harness"
di as text "{hline 79}"


/* ===================================================================== *
 * helper: build a Bai (2010) mean-shift panel
 *   Yit = mu_i1 + e_it        t <= k0
 *   Yit = mu_i2 + e_it        t >  k0
 * The break k0 is COMMON: one scalar, shared by every series (Bai eq.1).
 * mu_i2 - mu_i1 is HETEROGENEOUS: drawn ONCE PER SERIES, not per obs.
 * ===================================================================== */
capture program drop makebai
program define makebai
    syntax , n(integer) t(integer) k0(integer) [ dsd(real 1) esd(real 1) ///
             vratio(real 1) ]
    clear
    qui set obs `=`n'*`t''
    qui gen long id = ceil(_n/`t')
    qui bysort id: gen int t = _n
    xtset id t

    /* per-SERIES draws: generated on the first obs of each panel and
       spread with by-group max.  A per-observation runiform() here would
       make the shift idiosyncratic noise and destroy the DGP. */
    qui bysort id (t): gen double _d0 = (runiform()*2-1)*2*`dsd' if _n==1
    qui bysort id (t): egen double dshift = max(_d0)
    qui bysort id (t): gen double _m0 = rnormal(0,1) if _n==1
    qui bysort id (t): egen double mu1 = max(_m0)

    /* pre-break sd = esd ; post-break sd = esd*sqrt(vratio) */
    qui gen double e = rnormal(0,`esd')
    qui replace e = rnormal(0,`esd'*sqrt(`vratio')) if t>`k0'

    qui gen double y = mu1 + e
    qui replace y = mu1 + dshift + e if t>`k0'
    qui drop _d0 _m0
end


/* ===================================================================== *
 * helper: build a Jiang-Kurozumi panel
 *   y_it = x_it'b_i + x_it'd_i*1{t>k0_i} + u_it,  x = [1, z]
 *   z_it ~ N(1,1);  b_i ~ U(-0.8,0.8);  d_i ~ U(dlo,dhi)
 *   u_it = rho*u_i,t-1 + e_it,  e_it ~ N(0,(1-rho)^2)
 * group(2) sets a second group breaking at k0b (JK DGP.2 = H1A).
 * ===================================================================== */
capture program drop makejk
program define makejk
    syntax , n(integer) t(integer) k0(integer) [ k0b(integer 0) ///
             rho(real 0) dlo(real 0) dhi(real 0.5) share(real 0.5) ]
    clear
    qui set obs `=`n'*`t''
    qui gen long id = ceil(_n/`t')
    qui bysort id: gen int t = _n
    xtset id t

    qui gen double z = rnormal(1,1)

    /* per-SERIES coefficients */
    qui bysort id (t): gen double _b0 = (runiform()*1.6-0.8) if _n==1
    qui bysort id (t): egen double bcon = max(_b0)
    qui bysort id (t): gen double _b1 = (runiform()*1.6-0.8) if _n==1
    qui bysort id (t): egen double bz = max(_b1)
    qui bysort id (t): gen double _d1 = (runiform()*(`dhi'-`dlo')+`dlo') if _n==1
    qui bysort id (t): egen double dcon = max(_d1)
    qui bysort id (t): gen double _d2 = (runiform()*(`dhi'-`dlo')+`dlo') if _n==1
    qui bysort id (t): egen double dz = max(_d2)

    /* group membership and the per-series break date */
    qui gen byte grp = 1
    if (`k0b'>0) {
        qui replace grp = 2 if id > ceil(`n'*`share')
    }
    qui gen int kbrk = `k0'
    if (`k0b'>0) {
        qui replace kbrk = `k0b' if grp==2
    }

    /* AR(1) errors: built row-by-row AFTER sort, so L.u is already updated */
    qui gen double e = rnormal(0, (1-`rho'))
    if (`rho'==0) {
        qui replace e = rnormal(0,1)
    }
    sort id t
    qui gen double u = e
    if (`rho'!=0) {
        qui by id: replace u = `rho'*u[_n-1] + e if _n>1
    }

    qui gen double y = bcon + bz*z + u
    qui replace y = bcon + dcon + (bz+dz)*z + u if t>kbrk
    qui drop _b0 _b1 _d1 _d2
end


/* ===================================================================== *
 * PART 1.  Bai (2010) sec.3 -- consistency of khat as N grows
 *   His design: T=10, k0=5, mu_i2-mu_i1 ~ U(-2,2), e ~ N(0,1).
 *   His Fig.1: precision improves markedly with N; at N=100, ~100%.
 * ===================================================================== */
di as text _n "{hline 79}"
di as text "PART 1  Bai (2010) sec.3 DGP:  T=10, k0=5, shift ~ U(-2,2), e ~ N(0,1)"
di as text "        Bai Fig.1: khat should hit k0 essentially always by N=100."
di as text "{hline 79}"
di as text %8s "N" %14s "khat" %14s "k0(true)" %12s "hit?"
di as text "{hline 79}"

foreach nn of numlist 1 10 20 100 {
    set seed 20260717
    makebai, n(`nn') t(10) k0(5)
    qui xtcombreak estimate y
    local kh = r(khat)
    local hit = cond(`kh'==5,"YES","no")
    di as result %8.0f `nn' %14.0f `kh' %14.0f 5 %12s "`hit'"
}
di as text "{hline 79}"

/* the sharper reading of Bai's Fig.1: the HIT RATE over replications */
di as text _n "PART 1b  hit rate P(khat = k0) over 100 replications"
di as text "{hline 79}"
di as text %8s "N" %16s "P(khat=k0)" %30s "Bai's claim"
di as text "{hline 79}"
foreach nn of numlist 1 10 20 100 {
    local hits = 0
    forval r = 1/100 {
        set seed `=5000+`r''
        qui makebai, n(`nn') t(10) k0(5)
        qui xtcombreak estimate y
        if (r(khat)==5) local hits = `hits' + 1
    }
    local hr = `hits'/100
    local claim = ""
    if (`nn'==1)   local claim "hard with a single series"
    if (`nn'==100) local claim "should be ~1.00"
    di as result %8.0f `nn' %16.2f `hr' as text %30s "`claim'"
}
di as text "{hline 79}"
di as text "PASS if the hit rate rises monotonically in N and is ~1.00 at N=100."


/* ===================================================================== *
 * PART 1c.  Bai's single-observation-regime claim (his Fig.2)
 *   T=10, k0=9 -> the second regime holds ONE observation.
 *   This is the mode that needs NO trimming; it is why the default is
 *   trimming(0).  Any command that trims 15% cannot even consider k0=9.
 * ===================================================================== */
di as text _n "{hline 79}"
di as text "PART 1c  Bai Fig.2:  k0=9 with T=10 -- the LAST regime has ONE obs."
di as text "         Bai's headline: still consistent.  Requires trimming(0)."
di as text "{hline 79}"
foreach nn of numlist 10 100 {
    local hits = 0
    forval r = 1/100 {
        set seed `=7000+`r''
        qui makebai, n(`nn') t(10) k0(9)
        qui xtcombreak estimate y
        if (r(khat)==9) local hits = `hits' + 1
    }
    di as result %8.0f `nn' as text "  P(khat=9) = " as result %5.2f `hits'/100
}
di as text "PASS if this rises with N -- confirms no-trimming is faithful to Bai."


/* ===================================================================== *
 * PART 2.  Bai (2010) p.83 -- confidence interval coverage
 *   His design: T=100, k0=50, mu_i2-mu_i1 ~ sigma*U(-1,1), e ~ N(0,1).
 *   His Table 1 (N(0,1) panel), coverage at the 90/95/99% levels:
 *      N=5   0.829 0.886 0.954
 *      N=10  0.900 0.932 0.979
 *      N=15  0.937 0.968 0.989
 *      N=20  0.949 0.983 0.994
 *   and the median CI length shrinks as N grows.
 * ===================================================================== */
di as text _n "{hline 79}"
di as text "PART 2  Bai (2010) Table 1: CI coverage.  T=100, k0=50, shift ~ U(-1,1)"
di as text "{hline 79}"
di as text %6s "N" %12s "cover90" %12s "Bai 90" %12s "medlen" %12s "Bai len"
di as text "{hline 79}"

local bai90 "0.829 0.900 0.937 0.949"
local bailen "9 5 5 3"
local jj = 0
foreach nn of numlist 5 10 15 20 {
    local jj = `jj' + 1
    local cov = 0
    local lens ""
    forval r = 1/200 {
        set seed `=9000+`r''
        qui makebai, n(`nn') t(100) k0(50) dsd(0.5)
        qui xtcombreak estimate y, level(90)
        /* an r() matrix cannot be subscripted inside a local -- copy it out
           first (this bites in Stata 15; see xtbreak's own changelog). */
        matrix _CI = r(ci)
        local lo = _CI[1,3]
        local hi = _CI[1,4]
        if (`lo'<=50 & 50<=`hi') local cov = `cov' + 1
        local lens "`lens' `=`hi'-`lo'+1'"
    }
    capture matrix drop _CI
    local cr = `cov'/200
    local bb : word `jj' of `bai90'
    local bl : word `jj' of `bailen'
    /* median length */
    preserve
        clear
        qui set obs 200
        qui gen double L = .
        local q = 0
        foreach v of local lens {
            local q = `q' + 1
            qui replace L = `v' in `q'
        }
        qui su L, detail
        local ml = r(p50)
    restore
    di as result %6.0f `nn' %12.3f `cr' as text %12s "`bb'" as result %12.0f `ml' as text %12s "`bl'"
}
di as text "{hline 79}"
di as text "PASS if coverage rises toward/above nominal with N and length shrinks."
di as text "Bai's own note (p.84): for N>=15 coverage EXCEEDS nominal -- conservative"
di as text "intervals are expected, not a bug."

/* --------------------------------------------------------------------- *
 * PART 2b.  cimethod(): Bai's eq.(13) as PRINTED is not what he ran.
 *   Literal  [khat-floor(c/A), khat+ceil(c/A)] -> EVEN length, min 2
 *   Symmetric[khat-ceil(c/A),  khat+ceil(c/A)] -> ODD length,  min 3
 *   His prose (p.84) says the minimum is THREE; his Table 1 lengths are
 *   ODD (9,5,5,3 / 13,7,7,5 / 23,13,9,7).  Both point to symmetric.
 *   This part checks which one reproduces his published table.
 * --------------------------------------------------------------------- */
di as text _n "{hline 79}"
di as text "PART 2b  cimethod: which construction reproduces Bai's Table 1?"
di as text "{hline 79}"
di as text "  N | cov(lit) cov(sym) | Bai cov | len(lit) len(sym) | Bai len"
di as text "  --+-------------------+---------+-------------------+--------"

local bcs "0.829 0.900 0.937 0.949"
local bls "9 5 5 3"
local jj = 0
foreach nn of numlist 5 10 15 20 {
    local jj = `jj' + 1
    local cl = 0
    local cs = 0
    qui postfile PF int ll int ls using _cblen, replace
    forval r = 1/200 {
        set seed `=9000+`r''
        qui makebai, n(`nn') t(100) k0(50) dsd(0.5)
        qui xtcombreak estimate y, level(90) cimethod(literal)
        matrix _A = r(ci)
        local a3 = _A[1,3]
        local a4 = _A[1,4]
        if (`a3'<=50 & 50<=`a4') local cl = `cl' + 1
        qui xtcombreak estimate y, level(90) cimethod(symmetric)
        matrix _B = r(ci)
        local b3 = _B[1,3]
        local b4 = _B[1,4]
        if (`b3'<=50 & 50<=`b4') local cs = `cs' + 1
        qui post PF (`=`a4'-`a3'+1') (`=`b4'-`b3'+1')
    }
    qui postclose PF
    preserve
    qui use _cblen, clear
    qui su ll, detail
    local ml = r(p50)
    qui su ls, detail
    local ms = r(p50)
    restore
    local bc : word `jj' of `bcs'
    local bl : word `jj' of `bls'
    di as result "  " %2.0f `nn' as text " |  " as result %5.3f `cl'/200 "   " %5.3f `cs'/200 as text "  |  `bc'  |   " as result %3.0f `ml' "      " %3.0f `ms' as text "     |   `bl'"
}
capture matrix drop _A _B
di as text "{hline 79}"
di as text "PASS if len(sym) reproduces Bai's 9/5/5/3 and len(lit) is one short."
di as text "This is why cimethod(symmetric) is the default: it is what Bai ran."


/* ===================================================================== *
 * PART 3.  QML / GLS / variance breaks / multiple breaks / Chow
 * ===================================================================== */
di as text _n "{hline 79}"
di as text "PART 3  every estimate code path"
di as text "{hline 79}"

di as text _n "3a. method(ls) with a Chow table, N=20 T=60 k0=30"
set seed 111
makebai, n(20) t(60) k0(30) dsd(0.6)
xtcombreak estimate y, method(ls) chow showindex

di as text _n "3b. method(qml) -- same data.  A_N <= B_N must hold."
xtcombreak estimate y, method(qml)
di as text "  -> A_N = " as result %9.4f r(AN) as text "   B_N = " as result %9.4f r(BN)
if (r(BN) >= r(AN)-1e-8) {
    di as result "  PASS: A_N <= B_N (Cauchy-Schwarz, Bai p.85)"
}
else {
    di as error "  FAIL: A_N > B_N -- violates Bai p.85"
}

di as text _n "3c. method(gls) -- feasible GLS, asymptotically equivalent to QML"
xtcombreak estimate y, method(gls)

di as text _n "3d. VARIANCE break only (no mean break): sd doubles at k0."
di as text "    Bai Cor.5.4: QML stays consistent through the variance channel"
di as text "    alone; LS cannot see it at all."
set seed 222
makebai, n(40) t(60) k0(30) dsd(0) vratio(4)
di as text "    -- method(ls): expected to FAIL (no mean break to detect)"
qui xtcombreak estimate y, method(ls)
di as text "       khat = " as result r(khat) as text "  (true 30; LS is blind here by construction)"
di as text "    -- method(qml): expected to FIND k0=30"
qui xtcombreak estimate y, method(qml)
di as text "       khat = " as result r(khat) as text "  (true 30)"
if (abs(r(khat)-30)<=2) {
    di as result "    PASS: QML recovers a pure variance break (Bai eq.17 / Thm 5.1)"
}
else {
    di as error "    CHECK: QML missed the variance break"
}

di as text _n "3e. multiple breaks, one-at-a-time (Bai sec.6): true breaks 20 and 45"
clear
set seed 333
qui set obs 3000
qui gen long id = ceil(_n/60)
qui bysort id: gen int t = _n
xtset id t
/* NB: do NOT name a temporary variable _b -- _b is Stata's reserved
   coefficient vector (_b[varname]) and `gen _b' fails with r(198). */
qui bysort id (t): gen double q1 = (runiform()*2-1)*1.5 if _n==1
qui bysort id (t): egen double d1 = max(q1)
qui bysort id (t): gen double q2 = (runiform()*2-1)*1.5 if _n==1
qui bysort id (t): egen double d2 = max(q2)
qui gen double y = rnormal(0,1)
qui replace y = y + d1 if t>20
qui replace y = y + d2 if t>45
xtcombreak estimate y, breaks(2) showindex
di as text "  -> true breaks: 20 and 45"


/* ===================================================================== *
 * PART 4.  JK (2026) DGP.1 -- SIZE (null: one common break)
 *   JK Table 2, rho=0, nominal 5%:
 *     T=50  N=50   0.035        T=100 N=50   0.035
 *     T=100 N=100  0.028        T=200 N=100  0.041
 * ===================================================================== */
di as text _n "{hline 79}"
di as text "PART 4  Jiang-Kurozumi DGP.1 -- SIZE.  H0 true: ONE common break at 0.5T"
di as text "{hline 79}"
di as text %6s "T" %6s "N" %12s "size@10%" %12s "size@5%" %12s "JK Tab2 5%"
di as text "{hline 79}"

local jkt2 "0.035 0.028"
local jj = 0
foreach cfg in "50 50" "100 100" {
    local jj = `jj' + 1
    local TT : word 1 of `cfg'
    local NN : word 2 of `cfg'
    local r10 = 0
    local r05 = 0
    local nrep = 100
    forval r = 1/`nrep' {
        set seed `=13000+`r''
        qui makejk, n(`NN') t(`TT') k0(`=floor(0.5*`TT')') rho(0)
        qui xtcombreak test y z
        if (r(S)>r(cv10)) local r10 = `r10' + 1
        if (r(S)>r(cv05)) local r05 = `r05' + 1
    }
    local b : word `jj' of `jkt2'
    di as result %6.0f `TT' %6.0f `NN' %12.3f `r10'/`nrep' %12.3f `r05'/`nrep' as text %12s "`b'"
}
di as text "{hline 79}"
di as text "PASS if size is near nominal (0.10 / 0.05). JK warn size is DISTORTED"
di as text "at small T -- their Table 2 shows 0.092 at T=20,N=10 rising to 0.149."


/* ===================================================================== *
 * PART 5.  JK (2026) DGP.2 -- POWER (H1A: two groups, breaks 0.25T/0.75T)
 *   JK Table 4, rho=0, 5% level:
 *     T=50  N=50   0.827        T=100 N=100  1.000
 * ===================================================================== */
di as text _n "{hline 79}"
di as text "PART 5  Jiang-Kurozumi DGP.2 -- POWER.  H1A: 2 groups, breaks 0.25T & 0.75T"
di as text "{hline 79}"
di as text %6s "T" %6s "N" %12s "power@10%" %12s "power@5%" %12s "JK Tab4 5%"
di as text "{hline 79}"

local jkt4 "0.827 1.000"
local jj = 0
foreach cfg in "50 50" "100 100" {
    local jj = `jj' + 1
    local TT : word 1 of `cfg'
    local NN : word 2 of `cfg'
    local r10 = 0
    local r05 = 0
    local nrep = 100
    forval r = 1/`nrep' {
        set seed `=17000+`r''
        qui makejk, n(`NN') t(`TT') k0(`=floor(0.25*`TT')') ///
                    k0b(`=floor(0.75*`TT')') rho(0) share(0.5)
        qui xtcombreak test y z
        if (r(S)>r(cv10)) local r10 = `r10' + 1
        if (r(S)>r(cv05)) local r05 = `r05' + 1
    }
    local b : word `jj' of `jkt4'
    di as result %6.0f `TT' %6.0f `NN' %12.3f `r10'/`nrep' %12.3f `r05'/`nrep' as text %12s "`b'"
}
di as text "{hline 79}"
di as text "PASS if power is high (>0.8 at T=N=50) and ~1.00 at T=N=100."

di as text _n "5b. JK's OWN power caveat: shifts in OPPOSITE directions."
di as text "    JK sec.5 p.96: with delta ~ U(-0.5,0.5) the test LOSES power."
di as text "    The command should warn via the sign-concordance diagnostic."
set seed 444
makejk, n(50) t(50) k0(13) k0b(38) rho(0) dlo(-0.5) dhi(0.5)
xtcombreak test y z
di as text "    -> concordance = " as result %5.3f r(concord) as text " (near 0.5 = mixed; expect the warning)"


/* ===================================================================== *
 * PART 6.  ** THE CRITICAL COMPATIBILITY CHECK **
 *   Simulate JK Theorem 1 at eps=0.1 and compare to their Table 1.
 *   If the coded limiting functional is right, these must match.
 *      tau0=0.30 -> 45.457  57.897  93.472
 *      tau0=0.50 -> 45.476  57.809  85.984
 *      tau0=0.70 -> 46.487  59.175  93.728
 * ===================================================================== */
di as text _n "{hline 79}"
di as text "PART 6  ** CRITICAL **  simulated JK Theorem 1 vs published Table 1"
di as text "        If these match, the coded functional -- and the sample"
di as text "        statistic that mirrors it -- are faithful to the paper."
di as text "{hline 79}"
di as text %8s "tau0" %10s "level" %12s "simulated" %12s "JK Table 1" %10s "diff"
di as text "{hline 79}"

/* small panel just to have something xtset; the CVs do not depend on it */
set seed 555
qui makejk, n(20) t(100) k0(50) rho(0)

foreach tt in 0.30 0.50 0.70 {
    local kk = round(`tt'*100)
    /* drive tau0 by placing the break; then read the simulated CVs */
    qui makejk, n(20) t(100) k0(`kk') rho(0)
    qui xtcombreak test y z, simulate reps(5000) gridpoints(1000) seed(99)
    local s10 = r(cv10)
    local s05 = r(cv05)
    local s01 = r(cv01)

    if (`tt'==0.30) {
        local t10 = 45.457
        local t05 = 57.897
        local t01 = 93.472
    }
    if (`tt'==0.50) {
        local t10 = 45.476
        local t05 = 57.809
        local t01 = 85.984
    }
    if (`tt'==0.70) {
        local t10 = 46.487
        local t05 = 59.175
        local t01 = 93.728
    }
    di as result %8.2f `tt' as text %10s "10%" as result %12.3f `s10' %12.3f `t10' %10.2f `s10'-`t10'
    di as text   %8s ""    as text %10s "5%"  as result %12.3f `s05' %12.3f `t05' %10.2f `s05'-`t05'
    di as text   %8s ""    as text %10s "1%"  as result %12.3f `s01' %12.3f `t01' %10.2f `s01'-`t01'
}
di as text "{hline 79}"
di as text "PASS if the 10% and 5% columns agree to roughly +/- 2 and the 1% to"
di as text "+/- 6 (Monte Carlo error; JK used 10,000 reps, we use 5,000 here)."
di as text "A LARGE, SYSTEMATIC gap means the coded functional is wrong -- check"
di as text "the sum directions in eq.(10) and the separability reduction (EQ-B)."

di as text _n "6b. the Table 1 typo at tau0=0.39"
di as text "    Published 10% value reads 5.162; neighbours are ~45.2."
di as text "    xtcombreak stores 45.162.  Check the stored table is monotone-ish:"
qui makejk, n(20) t(100) k0(39) rho(0)
qui xtcombreak test y z
di as text "    tau0=0.39 -> cv10 = " as result %7.3f r(cv10) as text " (must be ~45.2, NOT 5.162)"
if (r(cv10)>40) {
    di as result "    PASS: the typo is corrected."
}
else {
    di as error "    FAIL: the published typo has leaked into the table."
}


/* ===================================================================== *
 * PART 7.  graphs and the full pipeline
 * ===================================================================== */
di as text _n "{hline 79}"
di as text "PART 7  graphs + xtcombreak all"
di as text "{hline 79}"

set seed 666
makebai, n(30) t(80) k0(40) dsd(0.5)
xtcombreak estimate y, method(qml) chow graph ///
    profname(g_prof) shiftname(g_shift)
di as text "  -> graphs g_prof, g_shift created"

set seed 777
makejk, n(40) t(80) k0(40) rho(0)
xtcombreak test y z, graph cusumname(g_cusum) shiftname(g_dsign)
di as text "  -> graphs g_cusum, g_dsign created"

capture graph combine g_prof g_shift g_cusum g_dsign, ///
    title("xtcombreak diagnostics") graphregion(color(white)) name(g_dash, replace)
if (_rc==0) {
    di as text "  -> dashboard g_dash created"
}

di as text _n "7b. the full recommended pipeline"
set seed 888
makejk, n(40) t(80) k0(40) rho(0)
xtcombreak all y z

di as text _n(2) "{hline 79}"
di as text "END of validation harness"
di as text "{hline 79}"
di as text "Referee checklist for the log above:"
di as text "  [ ] Part 1  hit rate rises in N, ~1.00 at N=100        (Bai Fig.1)"
di as text "  [ ] Part 1c k0=9 with T=10 recovered                   (Bai Fig.2)"
di as text "  [ ] Part 2  coverage near/above nominal, length falls  (Bai Table 1)"
di as text "  [ ] Part 2b len(sym) = 9/5/5/3 exactly; len(lit) one short"
di as text "  [ ] Part 3b A_N <= B_N                                 (Bai p.85)"
di as text "  [ ] Part 3d QML finds a pure variance break, LS does not (Bai Thm 5.1)"
di as text "  [ ] Part 3e breaks 20 and 45 recovered                 (Bai sec.6)"
di as text "  [ ] Part 4  size near 0.05                             (JK Table 2)"
di as text "  [ ] Part 5  power > 0.8 at T=N=50                      (JK Table 4)"
di as text "  [ ] Part 5b concordance ~0.5 triggers the warning      (JK sec.5)"
di as text "  [ ] Part 6  simulated CVs match Table 1  <-- THE KEY CHECK"
di as text "  [ ] Part 7  four graphs render"
di as text "{hline 79}"
