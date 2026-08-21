*! xttvpivmg 1.0.0  19aug2026
*! Time-varying parameter IV mean-group estimator for large heterogeneous panels
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! GitHub: https://github.com/merwanroudane
*!
*! Implements, faithfully to:
*!   Bai, Y., Marcellino, M. & Kapetanios, G. (2026) "Mean group instrumental
*!     variable estimation of time-varying large heterogeneous panels with
*!     endogenous regressors", Econometrics and Statistics 37, 26-41.
*!     <doi:10.1016/j.ecosta.2023.06.004>
*!   building on Giraitis, L., Kapetanios, G. & Marcellino, M. (2021)
*!     "Time-varying instrumental variable estimation", Journal of Econometrics
*!     224(2), 394-415.  <doi:10.1016/j.jeconom.2020.08.013>
*!
*! Estimation logic (full equation-by-equation map in: help xttvpivmg methods)
*!   Step 1  Kernel weights.  b_j,t(H) = K(|j-t|/H) and b_j,t(L) = K(|j-t|/L),
*!           H = T^h second stage, L = T^l first stage (BMK eq.5; H,L may differ).
*!   Step 2  First stage.  For each unit i and each date t, the kernel-weighted
*!           local OLS projection of x on z:  Psihat_it = (sum b(L) z z')^-1
*!           (sum b(L) z x')   (BMK eq.4).
*!   Step 3  Projection.  xhat_ij = Psihat_ij' z_ij, i.e. the first-stage matrix
*!           is evaluated AT THE SUMMATION INDEX j, not at the evaluation point t
*!           (BMK eq.3).  Exogenous regressors instrument themselves (BMK Rem.4).
*!   Step 4  Second stage.  betahat^IV_it = (sum b(H) xhat_ij x_ij')^-1
*!           (sum b(H) xhat_ij y_ij)   (BMK eq.3).
*!   Step 5  Mean group.  betahat_MG,t = (1/N) sum_i betahat^IV_it (BMK eq.8),
*!           generalising Pesaran & Smith (1995) to a time-varying mean path.
*!   Step 6  Variance.  Sigmahat_e,t = (1/N) sum_i (betahat_it - betahat_MG,t)
*!           (betahat_it - betahat_MG,t)'  (BMK eq.17); Var(betahat_MG,t) =
*!           Sigmahat_e,t / N by Theorem 1(ii).  Driven purely by coefficient
*!           heterogeneity: no HAC, no bootstrap.
*!   Step 7  Bandwidth.  Rule of thumb H = L = T^0.5, or the leave-one-unit-out
*!           cross-validation of BMK section 2.3 over a 2-D grid of (h,l).
*!   Step 8  Trimming.  Theorem 1(ii) is an interior-point result; report over
*!           t = H+1, ..., T-H (BMK section 3).

program define xttvpivmg, eclass sortpreserve
    version 14.0

    if replay() {
        if ("`e(cmd)'" != "xttvpivmg") error 301
        syntax [, Level(cilevel) AT(numlist) SUMmary noHEADer]
        xttvpivmg_display , level(`level') at(`at') `summary' `header'
        exit
    }

    syntax anything(equalok) [if] [in] [,          ///
        Kernel(string)                             ///
        H(real -1) L(real -1)                      ///
        BW(real -1) BWFirst(real -1)               ///
        CV HGrid(numlist >0 <1) LGrid(numlist >0 <1) ///
        CVDivisor(string) noCVTrim                 ///
        TRim(integer -1) noTRIMming                ///
        VCE(string)                                ///
        DEMean(string)                             ///
        noCONstant                                 ///
        Level(cilevel)                             ///
        AT(numlist) TREF(real -1)                  ///
        GRaph CVPlot NAME(string) COMBine          ///
        SUMmary FULL                               ///
        EXPParm(numlist min=2 max=2)               ///
        ]

    * ------------------------------------------------------------------ *
    * 1.  Parse  depvar [exogvars] (endog = instruments)                   *
    * ------------------------------------------------------------------ *
    local an `anything'
    local p1 = strpos("`an'", "(")
    local p2 = strpos("`an'", ")")
    if (`p1'==0 | `p2'==0 | `p2'<`p1') {
        di as err "syntax: {bf:xttvpivmg} {it:depvar} [{it:exogvars}] "  ///
                  "({it:endogvars} = {it:instruments}) [if] [in] [, options]"
        di as err "the ({it:endogvars} = {it:instruments}) block is required"
        exit 198
    }
    local pre   = substr("`an'", 1, `p1'-1)
    local inner = substr("`an'", `p1'+1, `p2'-`p1'-1)
    local post  = substr("`an'", `p2'+1, .)

    local eq = strpos("`inner'", "=")
    if (`eq'==0) {
        di as err "the parenthesised block must read ({it:endogvars} = {it:instruments})"
        exit 198
    }
    local endolist = substr("`inner'", 1, `eq'-1)
    local instlist = substr("`inner'", `eq'+1, .)

    gettoken depvar exo1 : pre
    local exolist "`exo1' `post'"

    if ("`depvar'"=="") {
        di as err "no dependent variable specified"
        exit 198
    }

    tsunab depvar : `depvar'
    if (trim("`exolist'")!="")  tsunab exolist  : `exolist'
    if (trim("`endolist'")=="") {
        di as err "no endogenous regressors specified inside the parentheses"
        exit 198
    }
    tsunab endolist : `endolist'
    if (trim("`instlist'")=="") {
        di as err "no instruments specified inside the parentheses"
        exit 198
    }
    tsunab instlist : `instlist'

    * ------------------------------------------------------------------ *
    * 2.  Panel setup and balance checks                                   *
    * ------------------------------------------------------------------ *
    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if ("`ivar'"=="" | "`tvar'"=="") {
        di as err "data must be {bf:xtset} with both a panel and a time variable"
        exit 459
    }
    local tdelta = r(tdelta)
    if ("`tdelta'"=="" | "`tdelta'"==".") local tdelta = 1
    local tsfmt "`r(tsfmt)'"
    if ("`tsfmt'"=="") local tsfmt : format `tvar'

    * resolve time-series operators FIRST: markout cannot take L./F./D.
    tsrevar `depvar'
    local yv "`r(varlist)'"
    local xv ""
    if (trim("`exolist'")!="") {
        tsrevar `exolist'
        local xv "`r(varlist)'"
    }
    tsrevar `endolist'
    local xvend "`r(varlist)'"
    tsrevar `instlist'
    local zvex "`r(varlist)'"

    marksample touse, novarlist
    markout `touse' `yv' `xv' `xvend' `zvex' `ivar' `tvar'

    qui count if `touse'
    if (r(N)==0) {
        di as err "no observations"
        exit 2000
    }

    * balanced, gap-free rectangle is required: the kernel sums run j = 1..T
    tempvar nobs ntim
    qui bysort `touse' `ivar' (`tvar') : gen long `nobs' = _N if `touse'
    qui su `nobs' if `touse', meanonly
    local Tmin = r(min)
    local Tmax = r(max)
    if (`Tmin' != `Tmax') {
        di as err "xttvpivmg requires a balanced panel with no gaps"
        di as err "unit lengths range from `Tmin' to `Tmax' in the estimation sample"
        di as err "use {bf:tsfill} / drop short units, or restrict the sample"
        exit 459
    }
    qui levelsof `tvar' if `touse', local(tlevels)
    local T : word count `tlevels'
    if (`T' != `Tmax') {
        di as err "units do not share a common time grid (T = `T' distinct dates "  ///
                  "but `Tmax' observations per unit)"
        exit 459
    }
    * the kernel uses |j-t| in INDEX units, so the date grid must be regular
    qui su `tvar' if `touse', meanonly
    local tspan = (r(max)-r(min))/`tdelta' + 1
    if (abs(`tspan'-`T') > 1e-6) {
        di as err "the time grid has gaps: `T' distinct dates spanning `tspan' periods"
        di as err "the kernel weights K(|j-t|/H) are defined on the time index, so a"
        di as err "gap-free regular grid is required -- use {bf:tsfill}"
        exit 459
    }

    qui count if `touse'
    local N = r(N)/`T'
    if (`N' < 2) {
        di as err "need at least 2 panel units for a mean-group estimator"
        exit 2001
    }

    * ------------------------------------------------------------------ *
    * 3.  Options                                                          *
    * ------------------------------------------------------------------ *
    if ("`kernel'"=="") local kernel "gaussian"
    local kernel = lower("`kernel'")
    local kk = 0
    if (substr("gaussian",1,max(3,length("`kernel'")))=="`kernel'")      local kk = 1
    if (substr("rectangle",1,max(3,length("`kernel'")))=="`kernel'")     local kk = 2
    if (substr("uniform",1,max(3,length("`kernel'")))=="`kernel'")       local kk = 2
    if (substr("epanechnikov",1,max(3,length("`kernel'")))=="`kernel'")  local kk = 3
    if (substr("exponential",1,max(3,length("`kernel'")))=="`kernel'")   local kk = 4
    if (`kk'==0) {
        di as err "kernel() must be one of: gaussian, epanechnikov, rectangle, exponential"
        exit 198
    }
    local kname "Gaussian"
    if (`kk'==2) local kname "Rectangle (uniform)"
    if (`kk'==3) local kname "Epanechnikov"
    if (`kk'==4) local kname "Exponential"

    local cpar = 1
    local apar = 1
    if ("`expparm'"!="") {
        local cpar : word 1 of `expparm'
        local apar : word 2 of `expparm'
    }

    if ("`vce'"=="") local vce "paper"
    local vce = lower("`vce'")
    if !inlist("`vce'","paper","mg") {
        di as err "vce() must be {bf:paper} (BMK eq. 17, divisor N^2) or {bf:mg} "  ///
                  "(Pesaran-Smith, divisor N(N-1))"
        exit 198
    }
    local vdiv = 0
    if ("`vce'"=="mg") local vdiv = 1

    if ("`cvdivisor'"=="") local cvdivisor "n"
    local cvdivisor = lower("`cvdivisor'")
    if !inlist("`cvdivisor'","n","nminus1") {
        di as err "cvdivisor() must be {bf:n} (as printed in BMK section 2.3) or {bf:nminus1}"
        exit 198
    }
    local cvdiv = 0
    if ("`cvdivisor'"=="nminus1") local cvdiv = 1

    if ("`demean'"=="") local demean "none"
    local demean = lower("`demean'")
    if !inlist("`demean'","none","fixed","tv") {
        di as err "demean() must be {bf:none}, {bf:fixed} or {bf:tv} (see BMK Remark 1)"
        exit 198
    }
    local dmode = 0
    if ("`demean'"=="fixed") local dmode = 1
    if ("`demean'"=="tv")    local dmode = 2

    * BMK Remark 1(b): residualising y and x on a constant leaves no intercept.
    * Keeping one would give an identically-zero column and a singular system.
    if (`dmode' > 0 & "`constant'"!="noconstant") {
        local constant "noconstant"
        di as txt "note: {bf:demean(`demean')} residualises out the intercept "  ///
                  "(BMK Remark 1(b)); {bf:noconstant} imposed"
    }

    local cvtrimflag = 1
    if ("`cvtrim'"=="nocvtrim") local cvtrimflag = 0

    * ---- bandwidth resolution ---------------------------------------- *
    local hexp = `h'
    local lexp = `l'
    local Hbw  = `bw'
    local Lbw  = `bwfirst'
    local docv = 0
    if ("`cv'"!="") local docv = 1

    if (`docv' & (`hexp'>0 | `lexp'>0 | `Hbw'>0 | `Lbw'>0)) {
        di as err "{bf:cv} cannot be combined with h(), l(), bw() or bwfirst()"
        exit 198
    }
    if (`Hbw'>0 & `hexp'>0) {
        di as err "specify either h() or bw(), not both"
        exit 198
    }
    if (`Lbw'>0 & `lexp'>0) {
        di as err "specify either l() or bwfirst(), not both"
        exit 198
    }

    if ("`hgrid'"=="") local hgrid "0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85"
    if ("`lgrid'"=="") local lgrid "0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85"

    local bwsel "rule of thumb (H = L = T^0.5)"
    if (`docv'==0) {
        * rule of thumb of BMK section 2.3 / Giraitis et al. (2018)
        if (`Hbw'<=0) {
            if (`hexp'<=0) local hexp = 0.5
            local Hbw = `T'^`hexp'
        }
        else local hexp = ln(`Hbw')/ln(`T')
        if (`Lbw'<=0) {
            if (`lexp'<=0) local lexp = `hexp'
            local Lbw = `T'^`lexp'
        }
        else local lexp = ln(`Lbw')/ln(`T')
        if (`h'>0 | `l'>0 | `bw'>0 | `bwfirst'>0) local bwsel "user-specified"
    }
    else {
        local nh : word count `hgrid'
        local nl : word count `lgrid'
        local bwsel "leave-one-unit-out CV (`nh' x `nl' = `=`nh'*`nl'' grid points)"
    }

    * ---- trimming ----------------------------------------------------- *
    local dotrim = 1
    if ("`trimming'"=="notrimming") local dotrim = 0

    * ------------------------------------------------------------------ *
    * 4.  Build the regressor / instrument matrices                        *
    * ------------------------------------------------------------------ *
    * x = [exog, endog] ; z = [exog, instruments]  (included exogenous
    * regressors instrument themselves -- BMK Remark 4)
    local xall "`xv' `xvend'"
    local zall "`xv' `zvex'"

    local kexo : word count `xv'
    local kend : word count `xvend'
    local kx = `kexo' + `kend'
    local pz : word count `zall'

    local addcons = 1
    if ("`constant'"=="noconstant") local addcons = 0
    local kfull = `kx' + `addcons'
    local pfull = `pz' + `addcons'

    if (`pfull' < `kfull') {
        di as err "underidentified: `pfull' instruments (incl. constant) for "  ///
                  "`kfull' regressors (incl. constant)"
        di as err "BMK require p >= k (model (1)-(2))"
        exit 481
    }

    * display names, in the order the columns are built
    local xnames ""
    if (trim("`exolist'")!="")  local xnames "`exolist'"
    local xnames "`xnames' `endolist'"
    if (`addcons') local xnames "`xnames' _cons"
    local xnames = trim(itrim("`xnames'"))

    local znames ""
    if (trim("`exolist'")!="")  local znames "`exolist'"
    local znames "`znames' `instlist'"
    if (`addcons') local znames "`znames' _cons"
    local znames = trim(itrim("`znames'"))

    * endogenous column positions inside x (exog first, then endog)
    local endopos ""
    forvalues j = 1/`kend' {
        local endopos "`endopos' `=`kexo'+`j''"
    }
    local endopos = trim("`endopos'")

    * ------------------------------------------------------------------ *
    * 5.  Sort and run the Mata engine                                     *
    * ------------------------------------------------------------------ *
    sort `touse' `ivar' `tvar'

    tempname BMG SEMG BI CVOBJ CVG

    local dofull = 0
    if ("`full'"!="") local dofull = 1

    if (`N'*`T'*`T' > 5e8) {
        di as txt "note: N*T^2 = " %12.0fc `=`N'*`T'*`T'' " -- estimation is O(N T^2) "  ///
                  "and may take a while"
    }

    mata: xttvpivmg_work( "`yv'", "`xall'", "`zall'", "`touse'",              ///
                          `N', `T', `addcons', `kk', `cpar', `apar',         ///
                          `docv', `hexp', `lexp', "`hgrid'", "`lgrid'",      ///
                          `cvdiv', `cvtrimflag', `vdiv', `dmode',            ///
                          `dotrim', `trim', `dofull',                        ///
                          "`endopos'",                                       ///
                          "`BMG'", "`SEMG'", "`BI'", "`CVOBJ'", "`CVG'" )

    * grab every r() value NOW: any later program call clears r()
    local cvmin = .
    if (`docv') {
        local hexp  = r(hopt)
        local lexp  = r(lopt)
        local cvmin = r(cvmin)
    }
    local Hbw   = r(H)
    local Lbw   = r(L)
    local trim  = r(trim)
    local t0    = r(t0)
    local t1    = r(t1)
    local nrep  = r(nrep)
    local nsing = r(nsing)
    local gotfull = r(full)
    if (`dofull' & !`gotfull') {
        di as txt "note: {bf:full} skipped -- N x reported dates = " ///
                  `=`N'*`nrep'' " exceeds the 10,000-row matrix limit"
    }

    if (`nrep' < 1) {
        di as err "no time points survive trimming: H = " %6.3f `Hbw'   ///
                  " implies t = " `=`trim'+1' ".." `=`T'-`trim''  " with T = `T'"
        di as err "use a smaller h()/bw(), or {bf:notrimming}"
        exit 2001
    }
    if (`nsing' > 0) {
        di as txt "note: `nsing' unit-date second-stage systems were singular and "  ///
                  "were dropped from the mean-group average at those dates"
    }

    * time labels for the reported window
    tempname TL
    matrix `TL' = J(`nrep',1,0)
    local ii = 0
    foreach tv0 of local tlevels {
        local ++ii
        if (`ii'>=`t0' & `ii'<=`t1') {
            matrix `TL'[`=`ii'-`t0'+1',1] = `tv0'
        }
    }
    matrix colnames `BMG'  = `xnames'
    matrix colnames `SEMG' = `xnames'

    * ------------------------------------------------------------------ *
    * 6.  Reference date for e(b) / e(V)                                   *
    * ------------------------------------------------------------------ *
    if (`tref' <= 0) {
        local rrow = ceil(`nrep'/2)
    }
    else {
        local rrow = 0
        forvalues r = 1/`nrep' {
            if (`TL'[`r',1]==`tref') local rrow = `r'
        }
        if (`rrow'==0) {
            di as err "tref(`tref') is not inside the reported window"
            exit 198
        }
    }
    local trefv = `TL'[`rrow',1]

    tempname b V
    matrix `b' = `BMG'[`rrow', 1...]
    matrix colnames `b' = `xnames'
    matrix `V' = J(`kfull',`kfull',0)
    forvalues a = 1/`kfull' {
        matrix `V'[`a',`a'] = (`SEMG'[`rrow',`a'])^2
    }
    matrix colnames `V' = `xnames'
    matrix rownames `V' = `xnames'

    * ------------------------------------------------------------------ *
    * 7.  Graphs  (BEFORE any ereturn matrix move -- see gotcha #6)        *
    * ------------------------------------------------------------------ *
    local gopt ""
    if ("`graph'"!="")               local gopt "`gopt' dograph"
    if ("`cvplot'"!="" & `docv')     local gopt "`gopt' docv"
    if ("`cvplot'"!="" & !`docv') {
        di as txt "note: {bf:cvplot} ignored -- no cross-validation was run (add {bf:cv})"
    }
    if ("`graph'"!="" & `nrep' < 3) {
        di as txt "note: {bf:graph} skipped -- only `nrep' date(s) survive trimming"
        local gopt : subinstr local gopt "dograph" ""
    }
    if (trim("`gopt'")!="") {
        xttvpivmg_graph, bmg("`BMG'") semg("`SEMG'") tl("`TL'")       ///
            nrep(`nrep') k(`kfull') names(`xnames') level(`level')    ///
            tsfmt("`tsfmt'") name("`name'") `combine' `gopt'          ///
            cvobj("`CVOBJ'") cvg("`CVG'")
    }

    * ------------------------------------------------------------------ *
    * 8.  Display                                                          *
    * ------------------------------------------------------------------ *
    ereturn post `b' `V', esample(`touse') depname(`depvar') obs(`=`N'*`T'')

    ereturn matrix bmg   = `BMG'
    ereturn matrix semg  = `SEMG'
    ereturn matrix tlist = `TL'
    if (`gotfull') {
        matrix colnames `BI' = `xnames'
        ereturn matrix bi = `BI'
    }
    if (`docv') {
        ereturn matrix cvobj = `CVOBJ'
        ereturn matrix cvgrid = `CVG'
    }

    ereturn scalar N_g   = `N'
    ereturn scalar T     = `T'
    ereturn scalar g_min = `T'
    ereturn scalar g_max = `T'
    ereturn scalar k_x   = `kfull'
    ereturn scalar p_z   = `pfull'
    ereturn scalar H     = `Hbw'
    ereturn scalar L     = `Lbw'
    ereturn scalar hexp  = `hexp'
    ereturn scalar lexp  = `lexp'
    ereturn scalar trim  = `trim'
    ereturn scalar nrep  = `nrep'
    ereturn scalar tref  = `trefv'
    ereturn scalar level = `level'
    ereturn scalar nsing = `nsing'
    if (`docv') ereturn scalar cvmin = `cvmin'

    ereturn local cmd      "xttvpivmg"
    ereturn local cmdline  "xttvpivmg `0'"
    ereturn local depvar   "`depvar'"
    ereturn local exogvars "`exolist'"
    ereturn local endogvars "`endolist'"
    ereturn local insts    "`instlist'"
    ereturn local xnames   "`xnames'"
    ereturn local znames   "`znames'"
    ereturn local ivar     "`ivar'"
    ereturn local tvar     "`tvar'"
    ereturn local tsfmt    "`tsfmt'"
    ereturn local kernel   "`kname'"
    ereturn local bwsel    "`bwsel'"
    ereturn local vcetype  "`vce'"
    ereturn local demean   "`demean'"
    ereturn local predict  "xttvpivmg_p"
    ereturn local properties "b V"

    xttvpivmg_display , level(`level') at(`at') `summary'
end


* ====================================================================== *
* Display                                                                *
* ====================================================================== *
program define xttvpivmg_display
    version 14.0
    syntax [, Level(cilevel) AT(numlist) SUMmary noHEADer]

    if ("`level'"=="") local level = c(level)

    tempname B SE TL
    matrix `B'  = e(bmg)
    matrix `SE' = e(semg)
    matrix `TL' = e(tlist)

    local k    = e(k_x)
    local nrep = e(nrep)
    local xn   "`e(xnames)'"
    local tvar "`e(tvar)'"
    local dfmt "`e(tsfmt)'"
    if ("`dfmt'"=="" | "`dfmt'"==".") local dfmt "%9.0g"

    local zc = invnormal(1-(1-`level'/100)/2)

    if ("`header'"!="noheader") {
        di ""
        di as txt "Time-varying parameter IV mean-group estimator (TVP-IV-MG)"
        di as txt "Bai, Marcellino & Kapetanios (2026), {it:Econometrics and Statistics} 37, 26-41"
        di as txt "{hline 78}"
        di as txt "Dependent variable  : " as res abbrev("`e(depvar)'",20)     ///
           _col(46) as txt "Panels (N)      = " as res %8.0f e(N_g)
        di as txt "Panel / time vars   : " as res abbrev("`e(ivar)'",9) " / "  ///
           abbrev("`e(tvar)'",9)                                               ///
           _col(46) as txt "Periods (T)     = " as res %8.0f e(T)
        di as txt "Kernel              : " as res %-22s "`e(kernel)'"          ///
           _col(46) as txt "Regressors (k)  = " as res %8.0f e(k_x)
        di as txt "Bandwidth H (2nd st): " as res %8.3f e(H)                   ///
           as txt "  = T^" as res %4.3f e(hexp)                                ///
           _col(46) as txt "Instruments (p) = " as res %8.0f e(p_z)
        di as txt "Bandwidth L (1st st): " as res %8.3f e(L)                   ///
           as txt "  = T^" as res %4.3f e(lexp)                                ///
           _col(46) as txt "Dates reported  = " as res %8.0f e(nrep)
        di as txt "Bandwidth selection : " as res "`e(bwsel)'"
        local vlab "unit-path dispersion, divisor N{c 94}2 (BMK eq. 17)"
        if ("`e(vcetype)'"=="mg") local vlab "unit-path dispersion, divisor N(N-1) (Pesaran-Smith)"
        di as txt "Variance            : " as res "`vlab'"
        if (e(trim)>0) {
            di as txt "Trimming            : " as res "t = " %4.0f `=e(trim)+1' ///
               " .. " %4.0f `=e(T)-e(trim)' as txt "  (interior points, Theorem 1(ii))"
        }
        else {
            di as txt "Trimming            : " as res "none" as txt            ///
               "  (boundary estimates are one-sided and biased)"
        }
        di as txt "{hline 78}"
    }

    * ---- which dates to tabulate ------------------------------------- *
    local rows ""
    if ("`at'"!="") {
        foreach a of local at {
            local rr = 0
            forvalues r = 1/`nrep' {
                if (`TL'[`r',1]==`a') local rr = `r'
            }
            if (`rr'==0) {
                di as err "at(): `a' is not inside the reported window"
                exit 198
            }
            local rows "`rows' `rr'"
        }
    }
    else {
        local npt = min(9,`nrep')
        if (`npt'==1) local rows "1"
        else {
            forvalues q = 0/`=`npt'-1' {
                local rr = round(1 + `q'*(`nrep'-1)/(`npt'-1))
                local rows "`rows' `rr'"
            }
        }
    }

    * ---- coefficient tables, one block per regressor ------------------ *
    local j = 0
    foreach vn of local xn {
        local ++j
        di ""
        di as txt "Time-varying mean-group coefficient on " as res "`vn'"
        di as txt "{hline 78}"
        di as txt %12s "`tvar'" " {c |}" _col(19) "Coef." _col(31) "Std. Err."  ///
           _col(44) "z" _col(51) "P>|z|" _col(60) "[`level'% Conf. Int.]"
        di as txt "{hline 13}{c +}{hline 64}"
        foreach r of local rows {
            local bb = `B'[`r',`j']
            local ss = `SE'[`r',`j']
            local tt = `TL'[`r',1]
            local tstr : di `dfmt' `tt'
            local tstr = trim("`tstr'")
            if (`ss'>0 & `ss'<.) {
                local zz = `bb'/`ss'
                local pp = 2*normal(-abs(`zz'))
                local lo = `bb' - `zc'*`ss'
                local hi = `bb' + `zc'*`ss'
                local st ""
                if (`pp'<0.10) local st "*"
                if (`pp'<0.05) local st "**"
                if (`pp'<0.01) local st "***"
                di as txt %12s "`tstr'" " {c |}" as res _col(16) %10.0g `bb'    ///
                   _col(29) %10.0g `ss' _col(41) %7.2f `zz' _col(50) %6.3f `pp' ///
                   _col(58) %10.0g `lo' _col(70) %10.0g `hi' " " as txt "`st'"
            }
            else {
                di as txt %12s "`tstr'" " {c |}" as res _col(16) %10.0g `bb'    ///
                   _col(29) as txt "        ."
            }
        }
        di as txt "{hline 78}"
    }
    di as txt "* p<0.10, ** p<0.05, *** p<0.01.  Std. Err. from eq. (17): "
    di as txt "  sqrt( Sigmahat_e,t[j,j] / N ),  z-tests are pointwise (no uniform band)."

    * ---- path summary ------------------------------------------------- *
    if ("`summary'"!="") {
        di ""
        di as txt "Summary of the estimated coefficient paths over the reported window"
        di as txt "{hline 78}"
        di as txt %-14s "Variable" " {c |}" _col(19) "Mean" _col(31) "Min"      ///
           _col(43) "Max" _col(55) "SD" _col(66) "% signif."
        di as txt "{hline 15}{c +}{hline 62}"
        local j = 0
        foreach vn of local xn {
            local ++j
            local sm = 0
            local s2 = 0
            local mn = .
            local mx = .
            local ns = 0
            forvalues r = 1/`nrep' {
                local bb = `B'[`r',`j']
                local ss = `SE'[`r',`j']
                local sm = `sm' + `bb'
                local s2 = `s2' + `bb'*`bb'
                if (`mn'>=. | `bb'<`mn') local mn = `bb'
                if (`mx'>=. | `bb'>`mx') local mx = `bb'
                if (`ss'>0 & `ss'<.) {
                    if (2*normal(-abs(`bb'/`ss')) < 0.05) local ns = `ns' + 1
                }
            }
            local mean = `sm'/`nrep'
            local sd = sqrt(max(0,`s2'/`nrep' - `mean'*`mean'))
            local pc = 100*`ns'/`nrep'
            di as txt %-14s abbrev("`vn'",14) " {c |}" as res _col(16) %10.0g `mean' ///
               _col(28) %10.0g `mn' _col(40) %10.0g `mx' _col(52) %10.0g `sd'   ///
               _col(64) %8.1f `pc'
        }
        di as txt "{hline 78}"
        di as txt "Descriptive only: BMK provide no inference for time-averaged coefficients."
    }

    local trstr : di `dfmt' e(tref)
    di ""
    di as txt "e(b) and e(V) hold the estimates at `tvar' = " as res trim("`trstr'") ///
       as txt " (see {bf:tref()});"
    di as txt "the full paths are in {bf:e(bmg)}, {bf:e(semg)} with dates in {bf:e(tlist)}."
end


* ====================================================================== *
* Graphs                                                                 *
* ====================================================================== *
program define xttvpivmg_graph
    version 14.0
    syntax , bmg(string) semg(string) tl(string) nrep(integer) k(integer)  ///
             names(string) [ level(cilevel) tsfmt(string) name(string)     ///
             COMBine DOGRAPH DOCV cvobj(string) cvg(string) ]

    if ("`level'"=="") local level = c(level)
    local zc = invnormal(1-(1-`level'/100)/2)
    if ("`name'"=="") local name "tvpivmg"

    preserve
    quietly {
        clear
        set obs `nrep'
        svmat double `tl', name(tt)
        svmat double `bmg',  name(bb)
        svmat double `semg', name(ss)
        if ("`tsfmt'"!="") format tt1 `tsfmt'

        local glist ""
        local j = 0
        foreach vn of local names {
            local ++j
            capture drop lo hi
            gen double lo = bb`j' - `zc'*ss`j'
            gen double hi = bb`j' + `zc'*ss`j'
            local ttl "`vn'"
            if ("`dograph'"!="") {
                twoway (rarea lo hi tt1, color(navy%20) lwidth(none))          ///
                       (line bb`j' tt1, lcolor(navy) lwidth(medthick))         ///
                       (function y=0, range(tt1) lcolor(gs8) lwidth(thin)      ///
                        lpattern(solid)),                                      ///
                    title("`ttl'", size(medium) color(black))                  ///
                    ytitle("") xtitle("")                                      ///
                    legend(off)                                                ///
                    graphregion(color(white)) plotregion(color(white))         ///
                    ylabel(, angle(horizontal) labsize(small) grid             ///
                           glcolor(gs14) glwidth(vthin))                       ///
                    xlabel(, labsize(small))                                   ///
                    name(`name'_`j', replace) nodraw
                local glist "`glist' `name'_`j'"
            }
        }
    }
    if ("`dograph'"!="") {
        if ("`combine'"!="" | `k'>1) {
            graph combine `glist',                                             ///
                title("Time-varying mean-group coefficients", size(medium))     ///
                subtitle("`level'% pointwise confidence bands (BMK eq. 17)",     ///
                         size(small) color(gs6))                                ///
                graphregion(color(white)) name(`name', replace)
        }
        else {
            graph display `name'_1
        }
    }
    restore

    if ("`docv'"!="") {
        preserve
        quietly {
            clear
            local nn = rowsof(`cvg')
            set obs `nn'
            svmat double `cvg', name(g)
            svmat double `cvobj', name(o)
            label var g1 "h  (H = T^h)"
            label var g2 "l  (L = T^l)"
        }
        twoway (scatter g1 g2 [aw=1/o1], msymbol(circle) mcolor(navy%40)),      ///
            title("Leave-one-unit-out CV surface", size(medium))                ///
            subtitle("larger marker = lower CV objective", size(small) color(gs6)) ///
            ytitle("h   (H = T{sup:h}, second stage)")                          ///
            xtitle("l   (L = T{sup:l}, first stage)")                           ///
            graphregion(color(white)) plotregion(color(white))                  ///
            legend(off) name(`name'_cv, replace)
        restore
    }
end


* ====================================================================== *
* predict                                                                *
* ====================================================================== *
program define xttvpivmg_p
    version 14.0
    syntax newvarname [if] [in] [, XB Residuals ]

    if ("`e(cmd)'"!="xttvpivmg") error 301
    local nopt : word count `xb' `residuals'
    if (`nopt' > 1) {
        di as err "only one of xb or residuals may be specified"
        exit 198
    }
    if (`nopt'==0) local xb "xb"

    marksample touse, novarlist
    qui replace `touse' = 0 if !e(sample)

    tempname B TL
    matrix `B'  = e(bmg)
    matrix `TL' = e(tlist)
    local nrep = e(nrep)
    local tvar "`e(tvar)'"

    * rebuild the regressor columns exactly as at estimation
    local exolist "`e(exogvars)'"
    local endolist "`e(endogvars)'"
    local xl ""
    if (trim("`exolist'")!="") {
        tsrevar `exolist'
        local xl "`r(varlist)'"
    }
    tsrevar `endolist'
    local xl "`xl' `r(varlist)'"

    tempvar xbv
    qui gen double `xbv' = 0 if `touse'

    local j = 0
    foreach v of local xl {
        local ++j
        tempvar bser
        qui gen double `bser' = .
        forvalues r = 1/`nrep' {
            qui replace `bser' = `B'[`r',`j'] if `tvar'==`TL'[`r',1] & `touse'
        }
        qui replace `xbv' = `xbv' + `bser'*`v' if `touse'
        drop `bser'
    }
    * constant column, if any
    local kf = e(k_x)
    local nx : word count `xl'
    if (`kf' > `nx') {
        tempvar bser
        qui gen double `bser' = .
        forvalues r = 1/`nrep' {
            qui replace `bser' = `B'[`r',`kf'] if `tvar'==`TL'[`r',1] & `touse'
        }
        qui replace `xbv' = `xbv' + `bser' if `touse'
        drop `bser'
    }

    if ("`residuals'"!="") {
        tsrevar `e(depvar)'
        local yv "`r(varlist)'"
        gen double `varlist' = `yv' - `xbv' if `touse'
        label var `varlist' "Residuals (time-varying MG fit)"
    }
    else {
        gen double `varlist' = `xbv' if `touse'
        label var `varlist' "Linear prediction (time-varying MG coefficients)"
    }
end


* ====================================================================== *
* Mata engine                                                            *
* ====================================================================== *
version 14.0
mata:

// ---------------------------------------------------------------- //
// Kernel generator: g[d+1] = K(d/bw), d = 0,...,T-1  (BMK eq. 5, 7) //
// ---------------------------------------------------------------- //
real colvector _tvpiv_kgen(real scalar T, real scalar bw, real scalar ktype,
                           real scalar cpar, real scalar apar)
{
    real colvector d, g

    d = (0::(T-1)) :/ bw
    if (ktype==1) {
        // Gaussian  K(x) = exp(-x^2/2)
        g = exp(-0.5 :* (d:^2))
    } else if (ktype==2) {
        // rectangle / uniform  K(x) = (1/2) I{|x|<=1}; the 1/2 cancels
        g = (d :<= 1)
    } else if (ktype==3) {
        // Epanechnikov  K(x) = (3/4)(1-x^2) I{|x|<=1}
        g = 0.75 :* ((1 :- d:^2) :* (d :<= 1))
    } else {
        // exponential  K(x) = exp(-c x^alpha)
        g = exp(-cpar :* (d:^apar))
    }
    return(g)
}

// ---------------------------------------------------------------- //
// Weights b_{j,t} for a fixed t: pick g at |j-t|                     //
// ---------------------------------------------------------------- //
real colvector _tvpiv_wt(real colvector g, real scalar t, real scalar T)
{
    real colvector idx

    idx = abs((1::T) :- t) :+ 1
    return(g[idx])
}

// ---------------------------------------------------------------- //
// Kernel-smoothed demeaning (BMK Remark 1, time-varying version)     //
// ---------------------------------------------------------------- //
real matrix _tvpiv_tvdemean(real matrix A, real colvector g, real scalar T)
{
    real matrix R
    real scalar t, sw
    real colvector w

    R = A
    for (t=1; t<=T; t=t+1) {
        w = _tvpiv_wt(g, t, T)
        sw = colsum(w)
        R[t,.] = A[t,.] :- (quadcross(w, A) :/ sw)
    }
    return(R)
}

// ---------------------------------------------------------------- //
// Per-unit time-varying IV estimator                                 //
//   first stage  (BMK eq. 4), projection at index j (BMK eq. 3),     //
//   second stage (BMK eq. 3)                                         //
// returns T x k matrix of betahat^IV_it; missing rows = singular     //
// ---------------------------------------------------------------- //
// First stage (BMK eq. 4) plus the projection xhat_ij = Psihat_ij' z_ij
// used inside eq. (3).  Depends on L only, so it is computed once per
// l-value and reused across the whole h-grid.
real matrix _tvpiv_xhat(real matrix X, real matrix Z, real colvector gL,
                        real rowvector endopos)
{
    real scalar T, t, ne
    real matrix Xh, Xe, Szz, Szx, Psi
    real colvector w

    T  = rows(X)
    ne = cols(endopos)

    // Exogenous regressors instrument themselves, so their local
    // projection on Z returns them exactly (they are columns of Z).
    // Only the endogenous columns need Psihat.  This is algebraically
    // identical to projecting all k columns, and is BMK Remark 4.
    Xh = X
    if (ne > 0) {
        Xe = X[., endopos]
        for (t=1; t<=T; t=t+1) {
            w   = _tvpiv_wt(gL, t, T)
            Szz = quadcross(Z, w, Z)
            Szx = quadcross(Z, w, Xe)
            Psi = invsym(Szz) * Szx
            // xhat_t = Psihat_t' z_t : the first-stage matrix is used
            // AT index t, i.e. at the summation index j of eq. (3)
            Xh[t, endopos] = Z[t,.] * Psi
        }
    }
    return(Xh)
}

// Second stage (BMK eq. 3), given the projected regressors.
real matrix _tvpiv_beta(real colvector y, real matrix X, real matrix Xh,
                        real colvector gH)
{
    real scalar T, k, t
    real matrix A, B, Bet
    real colvector w, bb

    T   = rows(y)
    k   = cols(X)
    Bet = J(T, k, .)
    for (t=1; t<=T; t=t+1) {
        w = _tvpiv_wt(gH, t, T)
        A = quadcross(Xh, w, X)
        B = quadcross(Xh, w, y)
        // A is NOT symmetric (xhat != x): use an LU solve, not invsym
        bb = lusolve(A, B)
        if (hasmissing(bb)==0) {
            Bet[t,.] = bb'
        }
    }
    return(Bet)
}

// ---------------------------------------------------------------- //
// All units, given (H, L): returns N*T x k stacked by unit           //
// ---------------------------------------------------------------- //
// ---------------------------------------------------------------- //
// BMK Remark 1(b): residualise y, x and z on a unit-specific         //
// constant, either time-invariant (dmode 1) or itself kernel-        //
// smoothed at bandwidth L (dmode 2).  Modifies its arguments in      //
// place, so that estimation AND the CV objective use the same data.  //
// ---------------------------------------------------------------- //
void _tvpiv_demean(real colvector y, real matrix X, real matrix Z,
                   real scalar N, real scalar T, real scalar dmode,
                   real colvector gL)
{
    real scalar i, r0, r1

    if (dmode==0) {
        return
    }
    for (i=1; i<=N; i=i+1) {
        r0 = (i-1)*T + 1
        r1 = i*T
        if (dmode==1) {
            // time-invariant fixed effect: plain within transform
            y[r0::r1]    = y[r0::r1] :- mean(y[r0::r1])
            X[r0::r1, .] = X[r0::r1, .] :- (J(T,1,1) * mean(X[r0::r1, .]))
            Z[r0::r1, .] = Z[r0::r1, .] :- (J(T,1,1) * mean(Z[r0::r1, .]))
        } else {
            // time-varying fixed effect: kernel-smoothed demeaning at L
            y[r0::r1]    = _tvpiv_tvdemean(y[r0::r1], gL, T)
            X[r0::r1, .] = _tvpiv_tvdemean(X[r0::r1, .], gL, T)
            Z[r0::r1, .] = _tvpiv_tvdemean(Z[r0::r1, .], gL, T)
        }
    }
}

// ---------------------------------------------------------------- //
// First stage for every unit.  Data must ALREADY be demeaned if that //
// was requested.  Depends on L only.                                 //
// ---------------------------------------------------------------- //
real matrix _tvpiv_allxhat(real matrix X, real matrix Z,
                           real scalar N, real scalar T,
                           real colvector gL, real rowvector endopos)
{
    real scalar i, r0, r1
    real matrix Xh

    Xh = J(N*T, cols(X), .)
    for (i=1; i<=N; i=i+1) {
        r0 = (i-1)*T + 1
        r1 = i*T
        Xh[r0::r1, .] = _tvpiv_xhat(X[r0::r1, .], Z[r0::r1, .], gL, endopos)
    }
    return(Xh)
}

// ---------------------------------------------------------------- //
// Second stage for every unit, given the projected regressors.       //
// Depends on H only.                                                 //
// ---------------------------------------------------------------- //
real matrix _tvpiv_allbeta(real colvector y, real matrix X, real matrix Xh,
                           real scalar N, real scalar T, real colvector gH)
{
    real scalar i, r0, r1
    real matrix Bet

    Bet = J(N*T, cols(X), .)
    for (i=1; i<=N; i=i+1) {
        r0 = (i-1)*T + 1
        r1 = i*T
        Bet[r0::r1, .] = _tvpiv_beta(y[r0::r1], X[r0::r1, .], Xh[r0::r1, .], gH)
    }
    return(Bet)
}

// ---------------------------------------------------------------- //
// Mean group across units at each date, skipping missing units       //
// returns T x k mean and T x 1 count                                 //
// ---------------------------------------------------------------- //
real matrix _tvpiv_mg(real matrix Bet, real scalar N, real scalar T,
                      real colvector cnt)
{
    real scalar i, t, j, k, r
    real matrix M

    k = cols(Bet)
    M = J(T, k, 0)
    cnt = J(T, 1, 0)
    for (i=1; i<=N; i=i+1) {
        for (t=1; t<=T; t=t+1) {
            r = (i-1)*T + t
            if (Bet[r,1] < .) {
                cnt[t] = cnt[t] + 1
                for (j=1; j<=k; j=j+1) {
                    M[t,j] = M[t,j] + Bet[r,j]
                }
            }
        }
    }
    for (t=1; t<=T; t=t+1) {
        if (cnt[t] > 0) {
            M[t,.] = M[t,.] :/ cnt[t]
        }
    }
    return(M)
}

// ---------------------------------------------------------------- //
// Leave-one-unit-out CV objective (BMK section 2.3)                  //
//   betahat^{-i}_MG,t = (1/N) sum_{j != i} betahat^IV_j,t   [paper]  //
//   or 1/(N-1) if cvdiv==1  (Sun, Carroll & Li 2009 convention)      //
//   objective = sum_i sum_t ( y_it - x_it' betahat^{-i}_MG,t )^2     //
// ---------------------------------------------------------------- //
real scalar _tvpiv_cvobj(real matrix Bet, real colvector y, real matrix X,
                         real scalar N, real scalar T, real scalar cvdiv,
                         real scalar ta, real scalar tb)
{
    real scalar i, t, r, obj, den, e, nn
    real matrix S
    real rowvector bmi
    real colvector cnt

    S = _tvpiv_mg(Bet, N, T, cnt) // S is the plain MG mean
    obj = 0
    nn  = 0
    for (i=1; i<=N; i=i+1) {
        for (t=ta; t<=tb; t=t+1) {
            r = (i-1)*T + t
            if (Bet[r,1] < . & cnt[t] > 1) {
                // sum over all units at t = S[t,.]*cnt[t]
                den = cnt[t]
                if (cvdiv==1) {
                    den = cnt[t] - 1
                }
                bmi = (S[t,.]:*cnt[t] :- Bet[r,.]) :/ den
                e   = y[r] - X[r,.]*bmi'
                obj = obj + e*e
                nn  = nn + 1
            }
        }
    }
    if (nn==0) {
        return(.)
    }
    return(obj)
}

// ---------------------------------------------------------------- //
// Main driver                                                        //
// ---------------------------------------------------------------- //
void xttvpivmg_work(string scalar yv, string scalar xv, string scalar zv,
                    string scalar touse,
                    real scalar N, real scalar T, real scalar addcons,
                    real scalar ktype, real scalar cpar, real scalar apar,
                    real scalar docv, real scalar hexp, real scalar lexp,
                    string scalar hgrid, string scalar lgrid,
                    real scalar cvdiv, real scalar cvtrim,
                    real scalar vdiv, real scalar dmode,
                    real scalar dotrim, real scalar trimin, real scalar dofull,
                    string scalar endostr,
                    string scalar bmgnm, string scalar semgnm, string scalar binm,
                    string scalar cvobjnm, string scalar cvgnm)
{
    real colvector y, cnt, hg, lg, cvvals, gH, gL, yt
    real matrix X, Z, Bet, MG, SE, VV, CVG, Xh, Xt, Zt
    real rowvector endopos
    real scalar k, i, t, j, r, H, L, trim, ta, tb, nrep, nsing
    real scalar a, b, best, obj, hb, lb, ng, d, hh, ll
    real matrix Bout, SEout, Bfull

    y = st_data(., yv, touse)
    X = st_data(., tokens(xv), touse)
    Z = st_data(., tokens(zv), touse)

    if (addcons==1) {
        X = X, J(rows(X), 1, 1)
        Z = Z, J(rows(Z), 1, 1)
    }
    k = cols(X)

    endopos = strtoreal(tokens(endostr))
    if (addcons==1) {
        // positions are unchanged: the constant is appended last and is exogenous
    }

    // ---- bandwidth selection ------------------------------------- //
    hh = hexp
    ll = lexp
    if (docv==1) {
        hg = strtoreal(tokens(hgrid))'
        lg = strtoreal(tokens(lgrid))'
        ng = rows(hg)*rows(lg)
        CVG    = J(ng, 2, .)
        cvvals = J(ng, 1, .)
        best = .
        hb = hg[1]
        lb = lg[1]
        // l is the OUTER loop: the first stage and the (possibly
        // kernel-smoothed) demeaning depend on L only, so each is
        // computed once per l-value and reused across the whole h-grid.
        d = 0
        for (b=1; b<=rows(lg); b=b+1) {
            L  = T^lg[b]
            gL = _tvpiv_kgen(T, L, ktype, cpar, apar)
            yt = y
            Xt = X
            Zt = Z
            _tvpiv_demean(yt, Xt, Zt, N, T, dmode, gL)
            Xh = _tvpiv_allxhat(Xt, Zt, N, T, gL, endopos)
            for (a=1; a<=rows(hg); a=a+1) {
                d  = (a-1)*rows(lg) + b
                H  = T^hg[a]
                gH = _tvpiv_kgen(T, H, ktype, cpar, apar)
                trim = 0
                if (cvtrim==1) {
                    trim = floor(H)
                }
                ta = trim + 1
                tb = T - trim
                CVG[d,1] = hg[a]
                CVG[d,2] = lg[b]
                if (ta <= tb) {
                    Bet = _tvpiv_allbeta(yt, Xt, Xh, N, T, gH)
                    obj = _tvpiv_cvobj(Bet, yt, Xt, N, T, cvdiv, ta, tb)
                    cvvals[d] = obj
                    if (obj < . & obj < best) {
                        best = obj
                        hb   = hg[a]
                        lb   = lg[b]
                    }
                }
            }
        }
        if (best >= .) {
            errprintf("cross-validation failed at every grid point\n")
            exit(498)
        }
        hh = hb
        ll = lb
        st_numscalar("r(hopt)", hh)
        st_numscalar("r(lopt)", ll)
        st_numscalar("r(cvmin)", best)
        st_matrix(cvobjnm, cvvals)
        st_matrix(cvgnm, CVG)
    }

    H = T^hh
    L = T^ll

    // ---- estimate at the selected bandwidths --------------------- //
    gH = _tvpiv_kgen(T, H, ktype, cpar, apar)
    gL = _tvpiv_kgen(T, L, ktype, cpar, apar)
    yt = y
    Xt = X
    Zt = Z
    _tvpiv_demean(yt, Xt, Zt, N, T, dmode, gL)
    Xh  = _tvpiv_allxhat(Xt, Zt, N, T, gL, endopos)
    Bet = _tvpiv_allbeta(yt, Xt, Xh, N, T, gH)
    MG  = _tvpiv_mg(Bet, N, T, cnt)

    nsing = 0
    for (i=1; i<=N; i=i+1) {
        for (t=1; t<=T; t=t+1) {
            r = (i-1)*T + t
            if (Bet[r,1] >= .) {
                nsing = nsing + 1
            }
        }
    }

    // ---- Step 6: variance (BMK eq. 17 / Theorem 1(ii)) ----------- //
    SE = J(T, k, .)
    VV = J(T, k, .)
    for (t=1; t<=T; t=t+1) {
        if (cnt[t] > 1) {
            for (j=1; j<=k; j=j+1) {
                obj = 0
                for (i=1; i<=N; i=i+1) {
                    r = (i-1)*T + t
                    if (Bet[r,1] < .) {
                        d   = Bet[r,j] - MG[t,j]
                        obj = obj + d*d
                    }
                }
                // Sigmahat_e,t[j,j] = obj / n_t  and Var = Sigmahat / n_t
                // paper  : divisor n_t^2       (vdiv==0)
                // Pes-Sm : divisor n_t(n_t-1)  (vdiv==1)
                if (vdiv==0) {
                    VV[t,j] = obj / (cnt[t]*cnt[t])
                } else {
                    VV[t,j] = obj / (cnt[t]*(cnt[t]-1))
                }
                SE[t,j] = sqrt(VV[t,j])
            }
        }
    }

    // ---- Step 8: trimming ---------------------------------------- //
    trim = 0
    if (dotrim==1) {
        trim = floor(H)
    }
    if (trimin >= 0) {
        trim = trimin
    }
    ta = trim + 1
    tb = T - trim
    nrep = tb - ta + 1
    if (nrep < 1) {
        nrep = 0
        ta = 1
        tb = 1
    }

    Bout  = MG[ta::tb, .]
    SEout = SE[ta::tb, .]

    st_matrix(bmgnm,  Bout)
    st_matrix(semgnm, SEout)

    // ---- per-unit paths over the reported window (option full) ---- //
    if (dofull==1 & nrep > 0) {
        if (N*nrep <= 10000) {
            Bfull = J(N*nrep, k, .)
            for (i=1; i<=N; i=i+1) {
                for (t=ta; t<=tb; t=t+1) {
                    Bfull[(i-1)*nrep + (t-ta+1), .] = Bet[(i-1)*T + t, .]
                }
            }
            st_matrix(binm, Bfull)
            st_numscalar("r(full)", 1)
        } else {
            st_numscalar("r(full)", 0)
        }
    } else {
        st_numscalar("r(full)", 0)
    }

    st_numscalar("r(H)", H)
    st_numscalar("r(L)", L)
    st_numscalar("r(trim)", trim)
    st_numscalar("r(t0)", ta)
    st_numscalar("r(t1)", tb)
    st_numscalar("r(nrep)", nrep)
    st_numscalar("r(nsing)", nsing)
}

end
