*! bootur 1.0.0  20jul2026
*! Bootstrap Unit Root Tests -- Stata port of the R package bootUR (Smeekes & Wilms)
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*! GitHub: https://github.com/merwanroudane
*-------------------------------------------------------------------------------
* Dispatcher.
*-------------------------------------------------------------------------------
program define bootur, rclass
    version 14.0
    gettoken sub rest : 0, parse(" ,")
    local sub = strlower("`sub'")
    if ("`sub'"=="_check") {
        _bucheck `rest'
    }
    else if ("`sub'"=="_pval") {
        _bupval `rest'
    }
    else if ("`sub'"=="adf") {
        _bu_adf `rest'
    }
    else if ("`sub'"=="ur") {
        _bu_boottest ur `rest'
    }
    else if ("`sub'"=="fdr") {
        _bu_boottest fdr `rest'
    }
    else if ("`sub'"=="sqt") {
        _bu_boottest sqt `rest'
    }
    else if ("`sub'"=="panel") {
        _bu_boottest panel `rest'
    }
    else if ("`sub'"=="union") {
        _bu_single union `rest'
    }
    else if ("`sub'"=="bootadf") {
        _bu_single bootadf `rest'
    }
    else if ("`sub'"=="order") {
        _bu_order `rest'
    }
    else if ("`sub'"=="diff") {
        _bu_diff `rest'
    }
    else if ("`sub'"=="plotmiss") {
        _bu_plotmiss `rest'
    }
    else if ("`sub'"=="plotorder") {
        _bu_plotorder `rest'
    }
    else {
        di as error "unknown bootur subcommand:  `sub'"
        di as error "valid: adf ur union bootadf fdr sqt panel order diff plotmiss plotorder"
        exit 198
    }
    return add
end

program define _bucheck, rclass
    * Hidden harness: compute the deterministic ADF engine for one series/spec.
    version 14.0
    syntax varname(numeric) [if] [in], DET(int) IC(int) SCALE(int) TWO(int) ///
        PMIN(int) PMAX(int) [QD(int 0)]
    marksample touse, novarlist
    tempname g t lag
    mata: _bu_check_one("`varlist'", "`touse'", `det', `ic', `scale', `two', ///
        `pmin', `pmax', `qd', "`g'", "`t'", "`lag'")
    return scalar gamma = `g'
    return scalar tstat = `t'
    return scalar lag   = `lag'
    return local icvec "`icvec'"
    return local shmin "`shmin'"
    return local umiss "`umiss'"
    return local ysmiss "`ysmiss'"
end

program define _bupval, rclass
    version 14.0
    syntax , STAT(real) CASE(string) NOBS(real)
    tempname p
    mata: st_numscalar("`p'", bu_fpval(`stat', "`case'", `nobs'))
    return scalar pval = `p'
end

*-------------------------------------------------------------------------------
* Shared driver for boot_ur / boot_fdr / boot_sqt / boot_panel
*-------------------------------------------------------------------------------
program define _bu_boottest, rclass
    version 14.0
    gettoken mode 0 : 0
    syntax varlist(numeric) [if] [in] [, BOOTstrap(string) B(integer 1999)       ///
        BLOCKlength(integer -1) AR(real -1) MINlag(integer 0) MAXlag(integer -1) ///
        CRITerion(string) SCale(integer 1) DETerministics(string) DETRend(string) ///
        UNION(integer 1) LEVel(real 0.05) STEPs(numlist) SEED(integer -1)         ///
        Dataname(string) noDOTs ]
    local B "`b'"

    * ---- resolve mode ----
    local modenum = cond("`mode'"=="ur",1, cond("`mode'"=="fdr",2, ///
                    cond("`mode'"=="sqt",3,4)))

    * ---- bootstrap method ----
    if ("`bootstrap'"=="") local bootstrap "AWB"
    local bootstrap = strupper("`bootstrap'")
    local boot = 0
    foreach k in MBB BWB DWB AWB SB SWB {
        local ++boot
        if ("`bootstrap'"=="`k'") local bootcode = `boot'
    }
    if ("`bootcode'"=="") {
        di as error "bootstrap() must be one of MBB BWB DWB AWB SB SWB"
        exit 198
    }

    * ---- information criterion ----
    if ("`criterion'"=="") local criterion "MAIC"
    local criterion = strupper("`criterion'")
    local ic = 0
    foreach k in AIC BIC MAIC MBIC {
        local ++ic
        if ("`criterion'"=="`k'") local iccode = `ic'
    }
    if ("`iccode'"=="") {
        di as error "criterion() must be one of AIC BIC MAIC MBIC"
        exit 198
    }

    * ---- sample ----
    marksample touse, novarlist
    markout `touse', strok
    qui count if `touse'
    local T = r(N)
    local N : word count `varlist'
    if (`T' < 10) {
        di as error "too few observations"
        exit 2001
    }
    if (`level'*(`B'+1) < 1) {
        di as error "B too low to perform the test at significance level `level'"
        exit 198
    }

    * ---- union vs deterministic specification ----
    if (`union') {
        if ("`deterministics'"!="") ///
            di as text "note: deterministics() ignored for the union test"
        if ("`detrend'"!="") ///
            di as text "note: detrend() ignored for the union test"
        local dc = 2
        local detr = 1
    }
    else {
        if ("`deterministics'"=="") local deterministics "intercept"
        local dc = cond("`deterministics'"=="none",0, ///
                   cond("`deterministics'"=="intercept",1, ///
                   cond("`deterministics'"=="trend",2,-1)))
        if (`dc'==-1) {
            di as error "deterministics() must be none, intercept or trend"
            exit 198
        }
        if ("`detrend'"=="") local detrend "OLS"
        local detrend = strupper("`detrend'")
        local detr = cond("`detrend'"=="OLS",1,cond("`detrend'"=="QD",2,-1))
        if (`detr'==-1) {
            di as error "detrend() must be OLS or QD"
            exit 198
        }
    }

    * ---- block length / AR parameter ----
    if (`blocklength' < 0) local blocklength = round(1.75*`T'^(1/3))
    if (`ar' < 0) local ar = 0.01^(1/`blocklength')

    * ---- max lag (Schwert-type rule, small-sample corrected) ----
    if (`maxlag' < 0) {
        local maxlag = floor(round(12*(`T'/100)^(1/4)) ///
                       - 7*max(1-`T'/50,0)*(`T'/100)^(1/4))
        if (`bootcode'==1) {
            local pib = 1 - (1 - (1/(`T'-`blocklength'))^(ceil(`T'/`blocklength')-1))^`B'
            if (`pib' > 0.01) local maxlag = min(`maxlag', `blocklength')
        }
    }
    if (`maxlag' < `minlag') local maxlag = `minlag'

    * ---- missing-value / unbalancedness handling ----
    tempname jflag
    mata: st_numscalar("`jflag'", bu_check_missing("`varlist'", "`touse'"))
    if (`jflag' == 1) {
        di as error "internal missing values detected inside the sample"
        exit 416
    }
    local joint = 1
    tempname allbal
    mata: st_numscalar("`allbal'", bu_all_balanced("`varlist'", "`touse'"))
    if (`allbal'==0) {
        if (inlist(`bootcode',1,5)) {
            if (`modenum'==1 & `N'>1) {
                local joint = 0
                di as text ///
"note: missing values cause the resampling bootstrap to be run for each series individually"
            }
            else {
                di as error ///
"resampling-based bootstraps MBB and SB cannot handle unbalanced series"
                exit 416
            }
        }
    }
    if (inlist(`bootcode',5,6) & `modenum'!=1) ///
di as text "note: SB and SWB are only recommended for the ur test; see help bootur"

    * ---- steps for the sequential quantile test ----
    tempname PVEC
    if (`modenum'==3) {
        _bu_makesteps `N' "`steps'"
        matrix `PVEC' = r(pvec)
    }
    else {
        matrix `PVEC' = (0)
    }

    * ---- run the engine ----
    if (`seed' >= 0) set seed `seed'
    local showdots = cond("`dots'"=="nodots",0,1)
    if (`showdots') di as text "Bootstrapping (B = `B') " _continue
    tempname OPT
    matrix `OPT' = (`bootcode', `B', `blocklength', `ar', `iccode', `scale', ///
        0.1, `minlag', `maxlag', `union', `dc', `detr', `level', `joint', ///
        `modenum', `showdots')
    mata: bu_run("`varlist'", "`touse'", st_matrix("`OPT'"), "`PVEC'")
    if (`showdots') di as text " done"

    local D = __bu_D
    if ("`dataname'"=="") local dataname "`varlist'"
    local detrname = cond(`detr'==1,"OLS","QD")
    local detname  = cond(`dc'==0,"none",cond(`dc'==1,"intercept","trend"))

    _bu_report, mode(`modenum') union(`union') n(`N') d(`D') level(`level') ///
        boot(`bootstrap') crit(`criterion') detname(`detname') detrname(`detrname') ///
        blocklength(`blocklength') breps(`B') maxlag(`maxlag') minlag(`minlag') ///
        dataname(`dataname') series(`varlist')

    return add
end

program define _bu_makesteps, rclass
    * Build the (increasing) p-vector for BSQT from user 'steps' (units or quantiles)
    args N steps
    if ("`steps'"=="") {
        numlist "0/`N'"
        local steps "`r(numlist)'"
    }
    * units (all non-negative integers) vs quantiles (values in [0,1])
    local isunit = 1
    foreach s of numlist `steps' {
        if (`s' != int(`s') | `s' < 0) local isunit = 0
    }
    tempname pv
    if (`isunit') {
        local pl "`steps'"
    }
    else {
        * quantiles in [0,1] -> integer group boundaries
        local pl ""
        foreach s of numlist `steps' {
            local pl "`pl' `=round(`s'*`N')'"
        }
    }
    * sort, unique, clamp to <=N, prepend 0 / append N
    numlist "`pl'", sort
    local pl "`r(numlist)'"
    local clean ""
    local prev "."
    foreach s of numlist `pl' {
        if (`s' <= `N' & "`s'"!="`prev'") {
            local clean "`clean' `s'"
            local prev "`s'"
        }
    }
    local first : word 1 of `clean'
    if (`first' > 0) local clean "0 `clean'"
    local last : word `=wordcount("`clean'")' of `clean'
    if (`last' < `N') local clean "`clean' `N'"
    matrix `pv' = J(1, wordcount("`clean'"), 0)
    local i = 0
    foreach s of numlist `clean' {
        local ++i
        matrix `pv'[1,`i'] = `s'
    }
    return matrix pvec = `pv'
end

*-------------------------------------------------------------------------------
* Output formatter + stored results for the bootstrap tests
*-------------------------------------------------------------------------------
program define _bu_report, rclass
    version 14.0
    syntax , mode(int) union(int) n(int) d(int) level(real) boot(string) ///
        crit(string) detname(string) detrname(string) blocklength(int) ///
        breps(int) maxlag(int) minlag(int) dataname(string) series(string)

    tempname est stat pval dstat dpar dlag dpval
    matrix `est'  = __bu_est
    matrix `stat' = __bu_stat
    matrix `pval' = __bu_pval
    matrix `dstat'= __bu_dstat
    matrix `dpar' = __bu_dpar
    matrix `dlag' = __bu_dlag
    matrix `dpval'= __bu_dpval

    local unitxt = cond(`union',"union ","")
    if (`mode'==1)      local mtxt "`boot' bootstrap `unitxt'test on each individual series"
    else if (`mode'==2) local mtxt "`boot' bootstrap `unitxt'test with false discovery rate control"
    else if (`mode'==3) local mtxt "`boot' bootstrap sequential quantile `unitxt'test"
    else                local mtxt "Panel `boot' bootstrap group-mean `unitxt'test"

    di ""
    di as text "`mtxt'"
    di as text "Data: " as result "`dataname'" as text "   (T-based block length = " ///
        as result "`blocklength'" as text ", B = " as result "`breps'" as text ")"
    if (`mode'==4) {
        di as text "H0: all series have a unit root" _col(48) ///
            "Ha: some series are stationary"
    }
    else {
        di as text "H0: series has a unit root" _col(48) "Ha: series is stationary"
    }
    if (!`union') di as text "Deterministics: " as result "`detname'" ///
        as text "   Detrending: " as result "`detrname'"
    di as text "{hline 73}"

    * ---------- mode-specific body ----------
    if (`mode'==4) {
        * panel group-mean
        local gm  = __bu_gm
        local gmp = __bu_gmp
        di as text %-30s "Group-mean statistic" as result %14.4f `gm'
        di as text %-30s "Bootstrap p-value"    as result %14.4f `gmp'
        di as text "{hline 73}"
        return scalar statistic = `gm'
        return scalar p_value   = `gmp'
        return scalar N_series  = `n'
    }
    else if (`mode'==1) {
        * individual tests
        di as text %-16s "series" %14s "est.root" %14s "statistic" %14s "p-value" %9s "reject"
        di as text "{hline 73}"
        local rej ""
        forvalues i = 1/`n' {
            local nm : word `i' of `series'
            local e  = `est'[`i',1]
            local s  = `stat'[`i',1]
            local p  = `pval'[`i',1]
            local star = cond(`p'<`level',"*"," ")
            local rej "`rej' `=(`p'<`level')'"
            if (`union') {
                di as text %-16s abbrev("`nm'",16) %14s "  ." ///
                    as result %14.4f `s' %14.4f `p' %8s "`star'"
            }
            else {
                di as text %-16s abbrev("`nm'",16) as result %14.4f (`e'+1) ///
                    %14.4f `s' %14.4f `p' as text %8s "`star'"
            }
        }
        di as text "{hline 73}"
        di as text "* rejects H0 at the `=`level'*100'% level"
        if (`n'==1) {
            return scalar statistic = `stat'[1,1]
            return scalar p_value   = `pval'[1,1]
            return scalar estimate  = `est'[1,1]
        }
        else {
            matrix rownames `stat' = `series'
            matrix rownames `pval' = `series'
            matrix rownames `est'  = `series'
            return matrix statistic = `stat'
            return matrix p_value   = `pval'
            return matrix estimate  = `est'
        }
    }
    else {
        * fdr / sqt: sequence of tests + rejections
        tempname rej seq
        matrix `rej' = __bu_rej
        matrix `seq' = __bu_seq
        if (`mode'==2) {
            di as text "Step-down sequence (false discovery rate control):"
            di as text %-10s "series" %16s "statistic" %16s "crit. value"
            di as text "{hline 44}"
            local ns = rowsof(`seq')
            forvalues i = 1/`ns' {
                local idx = `seq'[`i',1]
                local nm : word `idx' of `series'
                di as text %-10s abbrev("`nm'",10) as result ///
                    %16.4f `seq'[`i',2] %16.4f `seq'[`i',3]
            }
        }
        else {
            di as text "Sequential quantile test steps:"
            di as text %6s "step" %10s "H0 #I(0)" %10s "H1 #I(0)" %14s "statistic" %12s "p-value"
            di as text "{hline 54}"
            local ns = rowsof(`seq')
            forvalues i = 1/`ns' {
                di as text %6.0f `i' %10.0f `seq'[`i',1] %10.0f `seq'[`i',2] ///
                    as result %14.4f `seq'[`i',4] %12.4f `seq'[`i',5]
            }
        }
        di as text "{hline 54}"
        * rejections summary
        local nrej = 0
        forvalues i = 1/`n' {
            if (`rej'[`i',1]==1) local ++nrej
        }
        di as text "Series for which H0 (unit root) is rejected: " as result "`nrej'" as text " of `n'"
        forvalues i = 1/`n' {
            if (`rej'[`i',1]==1) {
                local nm : word `i' of `series'
                di as result "    `nm'"
            }
        }
        matrix rownames `rej' = `series'
        return matrix rejections = `rej'
        return matrix sequence   = `seq'
    }
    matrix rownames `dstat' = `series'
    matrix rownames `dpar'  = `series'
    matrix rownames `dlag'  = `series'
    matrix rownames `dpval' = `series'
    return matrix indiv_stat  = `dstat'
    return matrix indiv_est   = `dpar'
    return matrix indiv_lag   = `dlag'
    return matrix indiv_pval  = `dpval'
    return local bootstrap "`boot'"
    return local criterion "`crit'"
    return scalar level    = `level'
    return scalar block_length = `blocklength'
    return scalar B        = `breps'
end

*-------------------------------------------------------------------------------
* Placeholder subcommands (implemented later in this file)
*-------------------------------------------------------------------------------
program define _bu_single, rclass
    version 14.0
    gettoken which 0 : 0
    if ("`which'"=="union")   _bu_boottest ur `0' union(1)
    else                      _bu_boottest ur `0' union(0)
    return add
end

*-------------------------------------------------------------------------------
* adf : standard augmented Dickey-Fuller test with MacKinnon asymptotic p-value
*-------------------------------------------------------------------------------
program define _bu_adf, rclass
    version 14.0
    syntax varlist(numeric) [if] [in] [, DETerministics(string) MINlag(integer 0) ///
        MAXlag(integer -1) CRITerion(string) SCale(integer 1) ONEstep Dataname(string) ]

    local N : word count `varlist'
    if (`N' > 1) {
        di as error "adf handles a single time series; use {bf:bootur ur} for several"
        exit 198
    }
    if ("`deterministics'"=="") local deterministics "intercept"
    local dc = cond("`deterministics'"=="none",0, ///
               cond("`deterministics'"=="intercept",1, ///
               cond("`deterministics'"=="trend",2,-1)))
    if (`dc'==-1) {
        di as error "deterministics() must be none, intercept or trend"
        exit 198
    }
    if ("`criterion'"=="") local criterion "MAIC"
    local criterion = strupper("`criterion'")
    local ic = cond("`criterion'"=="AIC",1,cond("`criterion'"=="BIC",2, ///
               cond("`criterion'"=="MAIC",3,cond("`criterion'"=="MBIC",4,-1))))
    if (`ic'==-1) {
        di as error "criterion() must be one of AIC BIC MAIC MBIC"
        exit 198
    }
    local two = cond("`onestep'"=="",1,0)

    marksample touse, novarlist
    markout `touse', strok
    qui count if `touse'
    local T = r(N)
    if (`maxlag' < 0) {
        local maxlag = round(12*(`T'/100)^(1/4) - 7*max(1-`T'/50,0)*(`T'/100)^(1/4))
    }
    if (`maxlag' < `minlag') local maxlag = `minlag'

    tempname g t lag tt
    mata: bu_adf_run("`varlist'", "`touse'", `dc', `ic', `scale', `two', ///
        `minlag', `maxlag', "`g'", "`t'", "`lag'", "`tt'")
    local gamma = `g'
    local tstat = `t'
    local lag   = `lag'
    local TT    = `tt'

    * MacKinnon asymptotic p-value
    local case = cond(`dc'==0,"nc",cond(`dc'==1,"c","ct"))
    local Nreg = max(`TT'-`maxlag'-1, 20)
    tempname p
    mata: st_numscalar("`p'", bu_fpval(`tstat', "`case'", `Nreg'))
    local pval = `p'

    if ("`dataname'"=="") local dataname "`varlist'"
    local sttxt = cond(`two',"Two-step","One-step")
    di ""
    di as text "`sttxt' augmented Dickey-Fuller test (with `deterministics') on a single series"
    di as text "Data: " as result "`dataname'"
    di as text "H0: series has a unit root" _col(48) "Ha: series is stationary"
    di as text "{hline 60}"
    di as text %-24s "estimate of largest root" as result %14.5f (`gamma'+1)
    di as text %-24s "ADF test statistic"       as result %14.5f `tstat'
    di as text %-24s "MacKinnon p-value"         as result %14.5f `pval'
    di as text %-24s "selected lag length"       as result %14.0f `lag'
    di as text "{hline 60}"

    return scalar p_value  = `pval'
    return scalar statistic= `tstat'
    return scalar estimate = `gamma'
    return scalar lag      = `lag'
    return scalar N        = `TT'
    return local  criterion "`criterion'"
    return local  deterministics "`deterministics'"
end

*-------------------------------------------------------------------------------
* diff : difference multiple series, each by its own order (diff_mult)
*-------------------------------------------------------------------------------
program define _bu_diff, rclass
    version 14.0
    syntax varlist(numeric) [if] [in], Orders(numlist integer >=0) ///
        [ GENerate(string) replace ]
    local N : word count `varlist'
    local no : word count `orders'
    if (`no' != `N') {
        di as error "orders() must have `N' values, one per variable"
        exit 198
    }
    if ("`generate'"=="") local generate "d_"
    marksample touse, novarlist
    markout `touse', strok
    local outlist ""
    local i = 0
    foreach v of local varlist {
        local ++i
        local d : word `i' of `orders'
        local nv "`generate'`v'"
        if ("`replace'"!="") capture drop `nv'
        qui gen double `nv' = .
        mata: bu_diff_store("`v'", "`nv'", "`touse'", `d')
        label variable `nv' "D`d'.`v'"
        local outlist "`outlist' `nv'"
    }
    di as text "created differenced series: " as result "`outlist'"
    return local newvars "`outlist'"
end

*-------------------------------------------------------------------------------
* order : determine the order of integration of each series (order_integration)
*-------------------------------------------------------------------------------
program define _bu_order, rclass
    version 14.0
    syntax varlist(numeric) [if] [in], [ Method(string) MAXOrder(integer 2) ///
        LEVel(real 0.05) GENerate(string) * ]
    if ("`method'"=="") local method "ur"
    local N : word count `varlist'
    marksample touse, novarlist
    markout `touse', strok

    tempname order
    matrix `order' = J(1, `N', .)
    * indices of series still under consideration
    local active ""
    forvalues i = 1/`N' {
        local active "`active' `i'"
    }

    forvalues di = `=`maxorder'-1'(-1)0 {
        local nact : word count `active'
        if (`nact'==0) continue, break
        * difference the active series di times into tempvars
        local tvlist ""
        local avars ""
        foreach idx of local active {
            local v : word `idx' of `varlist'
            local avars "`avars' `v'"
            tempvar tv
            qui gen double `tv' = .
            mata: bu_diff_store("`v'", "`tv'", "`touse'", `di')
            local tvlist "`tvlist' `tv'"
        }
        * run the chosen test and obtain a rejection vector
        quietly _bu_order_test `method' `tvlist' , level(`level') `options'
        matrix _rej = r(rej)
        * classify
        local newactive ""
        local k = 0
        foreach idx of local active {
            local ++k
            local rj = _rej[1,`k']
            if (`rj'==0) {
                matrix `order'[1,`idx'] = `di' + 1
            }
            else {
                if (`di'==0) matrix `order'[1,`idx'] = 0
                else         local newactive "`newactive' `idx'"
            }
        }
        local active "`newactive'"
    }

    * display
    di ""
    di as text "Order of integration (method = `method', level = `level')"
    di as text "{hline 40}"
    di as text %-24s "series" %10s "order"
    di as text "{hline 40}"
    forvalues i = 1/`N' {
        local v : word `i' of `varlist'
        di as text %-24s abbrev("`v'",24) as result %8.0f `order'[1,`i']
    }
    di as text "{hline 40}"
    matrix colnames `order' = `varlist'
    return matrix order = `order'

    * optionally generate the differenced (stationary) series
    if ("`generate'"!="") {
        local ords ""
        forvalues i = 1/`N' {
            local ords "`ords' `=`order'[1,`i']'"
        }
        _bu_diff `varlist' if `touse', orders(`ords') generate(`generate') replace
        return local newvars "`r(newvars)'"
    }
end

program define _bu_order_test, rclass
    * run one unit-root test and return r(rej) = 1xk rejection row-vector
    version 14.0
    gettoken method 0 : 0
    syntax varlist [if] [in], level(real) [*]
    local k : word count `varlist'
    tempname rej
    if ("`method'"=="ur" | ("`method'"=="adf" & `k'>1)) {
        if ("`method'"=="adf") {
            matrix `rej' = J(1,`k',.)
            local j = 0
            foreach v of local varlist {
                local ++j
                bootur adf `v', `options'
                matrix `rej'[1,`j'] = (r(p_value) < `level')
            }
        }
        else {
            bootur ur `varlist', level(`level') `options'
            matrix P = r(p_value)
            matrix `rej' = J(1,`k',.)
            forvalues j = 1/`k' {
                matrix `rej'[1,`j'] = (P[`j',1] < `level')
            }
        }
    }
    else if ("`method'"=="fdr") {
        bootur fdr `varlist', level(`level') `options'
        matrix R = r(rejections)
        matrix `rej' = R'
    }
    else if ("`method'"=="sqt") {
        bootur sqt `varlist', level(`level') `options'
        matrix R = r(rejections)
        matrix `rej' = R'
    }
    else if ("`method'"=="adf") {
        bootur adf `varlist', `options'
        matrix `rej' = (r(p_value) < `level')
    }
    else if ("`method'"=="union" | "`method'"=="bootadf") {
        bootur `method' `varlist', level(`level') `options'
        matrix `rej' = (r(p_value) < `level')
    }
    else {
        di as error "invalid method(): `method'"
        exit 198
    }
    return matrix rej = `rej'
end

*-------------------------------------------------------------------------------
* plotmiss : visualise the pattern of missing values (plot_missing_values)
*-------------------------------------------------------------------------------
program define _bu_plotmiss, rclass
    version 14.0
    syntax varlist(numeric) [if] [in], [ Name(string) TITLE(string) ]
    marksample touse, novarlist
    markout `touse', strok
    preserve
    qui keep if `touse'
    local N : word count `varlist'
    tempvar obsid
    qui gen `obsid' = _n
    local T = _N
    * build the long tile dataset via mata (type codes 1..4)
    tempname TYPE
    mata: bu_missmap("`varlist'", "`TYPE'")
    * TYPE is (T*N) x 3 : varindex, obs, typecode
    drop _all
    qui svmat double `TYPE', name(mm)
    rename mm1 varidx
    rename mm2 obs
    rename mm3 mtype
    * label the x axis with variable names
    local vi = 0
    foreach v of local varlist {
        local ++vi
        label define _bumv `vi' "`v'", modify
    }
    label values varidx _bumv
    if ("`name'"=="") local name "bootur_missing"
    if (`"`title'"'=="") local title "Missing-value pattern"
    twoway ///
        (scatter obs varidx if mtype==1, ms(S) msize(*1.6) mcolor("77 175 74"))   ///
        (scatter obs varidx if mtype==2, ms(S) msize(*1.6) mcolor("55 126 184"))  ///
        (scatter obs varidx if mtype==3, ms(S) msize(*1.6) mcolor("152 78 163"))  ///
        (scatter obs varidx if mtype==4, ms(S) msize(*1.6) mcolor("228 26 28")),  ///
        legend(order(1 "Observed" 2 "Balanced NA" 3 "Unbalanced NA" 4 "Internal NA") ///
            rows(1) size(small)) ///
        xlabel(1(1)`N', valuelabel angle(45) noticks) ///
        ytitle("Observation") xtitle("") title(`"`title'"') ///
        graphregion(color(white)) plotregion(margin(zero)) ///
        name(`name', replace)
    restore
    di as text "missing-value map drawn (graph `name')"
end

*-------------------------------------------------------------------------------
* plotorder : bar chart of the orders of integration (plot_order_integration)
*-------------------------------------------------------------------------------
program define _bu_plotorder, rclass
    version 14.0
    syntax [anything] [, Name(string) TITLE(string) ]
    * anything: a matrix name (row vector of orders) or run after bootur order
    if ("`anything'"=="") local anything "r(order)"
    tempname M
    capture matrix `M' = `anything'
    if (_rc) {
        di as error "supply a (row) matrix of orders, e.g. plotorder ordmat"
        exit 198
    }
    local N = colsof(`M')
    preserve
    drop _all
    qui set obs `N'
    qui gen order = .
    qui gen sid   = _n
    local cn : colnames `M'
    forvalues i = 1/`N' {
        qui replace order = `M'[1,`i'] in `i'
        local nm : word `i' of `cn'
        if ("`nm'"=="") local nm "v`i'"
        label define _buord `i' "`nm'", modify
    }
    label values sid _buord
    if ("`name'"=="") local name "bootur_orders"
    if (`"`title'"'=="") local title "Order of integration"
    twoway (bar order sid, horizontal barwidth(0.7) ///
            fcolor("27 158 119") lcolor(white)), ///
        ylabel(1(1)`N', valuelabel angle(0) noticks) ///
        xlabel(0(1)`=max(2,`N')') xtitle("Order of integration") ytitle("") ///
        title(`"`title'"') graphregion(color(white)) name(`name', replace)
    restore
    di as text "orders-of-integration plot drawn (graph `name')"
end

version 14.0
mata:
mata clear
//-------------------------------------------------------------------------------
// struct holding one ADF fit
//-------------------------------------------------------------------------------
struct bu_adf {
    real scalar    t        // ADF t-statistic
    real scalar    c        // ADF normalised (coefficient) statistic
    real colvector par      // [gamma; lag coefficients]
    real colvector res      // full-model residuals e (length n)
    real colvector bres     // restricted residuals e_b (length n)
}

//-------------------------------------------------------------------------------
// lag matrix:  n x (p) with column j = x shifted down by j (first j rows 0),
// then (if trim) drop the first p rows.  Mirrors R lag_matrix() for a vector.
//-------------------------------------------------------------------------------
real matrix bu_lagmat(real colvector x, real scalar p, real scalar trim)
{
    real scalar n, j
    real matrix lx
    n = rows(x)
    if (p==0) return(J(n,0,0))
    lx = J(n, p, 0)
    for (j=0; j<=p-1; j++) {
        lx[|(j+2), (j+1) \ n, (j+1)|] = x[|1 \ (n-j-1)|]
    }
    if (trim) return(lx[|(p+1), 1 \ n, p|])
    return(lx)
}

//-------------------------------------------------------------------------------
// OLS coefficient vector
//-------------------------------------------------------------------------------
real colvector bu_ols(real colvector y, real matrix X)
{
    return(invsym(cross(X,X)) * cross(X,y))
}

//-------------------------------------------------------------------------------
// diff a vector: x - c*lag(x) ; if trim drop the first observation
//-------------------------------------------------------------------------------
real colvector bu_diffv(real colvector x, real scalar trim, real scalar c)
{
    real scalar n
    real colvector lx, dx
    n = rows(x)
    lx = J(n,1,0)
    lx[|2 \ n|] = x[|1 \ n-1|]
    dx = x - c*lx
    if (trim) return(dx[|2 \ n|])
    return(dx)
}

//-------------------------------------------------------------------------------
// diff a matrix (columnwise)
//-------------------------------------------------------------------------------
real matrix bu_diffm(real matrix x, real scalar trim, real scalar c)
{
    real scalar n, k
    real matrix lx, dx
    n = rows(x); k = cols(x)
    lx = J(n,k,0)
    lx[|2,1 \ n,k|] = x[|1,1 \ n-1,k|]
    dx = x - c*lx
    if (trim) return(dx[|2,1 \ n,k|])
    return(dx)
}

//-------------------------------------------------------------------------------
// (two-step) detrending: OLS (QD=0) or Quasi-Difference/GLS (QD=1)
// dc: 0 none, 1 intercept, 2 intercept+trend.  cbar = 7 (dc1), 13.5 (dc2).
//-------------------------------------------------------------------------------
real colvector bu_detrend(real colvector y, real scalar dc, real scalar QD)
{
    real scalar n, i, cn, cbar
    real matrix d, dQD
    real colvector yQD, b
    n = rows(y)
    if (dc<=0) return(y)
    d = J(n, dc, 0)
    for (i=0; i<=dc-1; i++) d[.,i+1] = (1::n):^i
    if (dc==1) cbar = 7
    else       cbar = 13.5
    if (QD) cn = 1 - cbar/n
    else    cn = 0
    dQD = bu_diffm(d, 0, cn)
    yQD = bu_diffv(y, 0, cn)
    b   = bu_ols(yQD, dQD)
    return(y - d*b)
}

//-------------------------------------------------------------------------------
// core ADF regression (two-step detrending).  Faithful port of adf_cpp().
//-------------------------------------------------------------------------------
struct bu_adf scalar bu_adf_fit(real colvector z, real scalar p, real scalar dc,
    real scalar QD, real scalar trim, real scalar trim_ic)
{
    real scalar n, trim_t, s2
    real colvector y, ylag, ydif, b, e, eb, els
    real matrix X, xxi, xls
    real colvector yls
    struct bu_adf scalar out

    n    = rows(z)
    y    = bu_detrend(z, dc, QD)
    ylag = J(n,1,0); ylag[|2 \ n|] = y[|1 \ n-1|]
    ydif = y - ylag
    if (p>0) X = ylag , bu_lagmat(ydif, p, 0)
    else     X = ylag

    if (trim_ic==0) trim_t = p
    else            trim_t = trim_ic

    if (trim) {
        xls = X[|(trim_t+2),1 \ n, cols(X)|]
        yls = ydif[|(trim_t+2) \ n|]
    }
    else {
        xls = X
        yls = ydif
    }
    xxi = invsym(cross(xls,xls))
    b   = xxi * cross(xls,yls)
    e   = ydif - X*b
    eb  = ydif - ylag*b[1]
    els = e[|(trim_t+2) \ n|]
    s2  = cross(els,els)/rows(els)

    out.t    = b[1]/sqrt(s2*xxi[1,1])
    out.c    = n*b[1]/(1 - sum(b) + b[1])
    out.par  = b
    out.res  = e
    out.bres = eb
    return(out)
}

//-------------------------------------------------------------------------------
// Nadaraya-Watson variance estimate used in the rescaled information criteria.
//-------------------------------------------------------------------------------
real colvector bu_npve(real colvector z, real scalar h)
{
    real scalar n
    real colvector r
    real matrix xm, k
    n  = rows(z)
    r  = (1::n)/n
    xm = (r*J(1,n,1) - J(n,1,1)*r') / h
    k  = normalden(xm)
    return( (k*(z:^2)) :/ rowsum(k) )
}

real colvector bu_rescale(real colvector y, real scalar h, real scalar p,
    real scalar dc, real scalar QD, real scalar trim, real scalar trim_ic)
{
    struct bu_adf scalar fit
    real colvector u, ydif, shat
    fit  = bu_adf_fit(y, p, dc, QD, trim, trim_ic)
    u    = fit.res
    ydif = bu_diffv(y, 0, 1)
    shat = sqrt(bu_npve(u, h))
    return( runningsum(ydif:/shat) )
}

//-------------------------------------------------------------------------------
// information criterion value.  ic: 1 AIC, 2 BIC, 3 MAIC, 4 MBIC.
//-------------------------------------------------------------------------------
real scalar bu_ic(real scalar ic, real colvector e, real scalar k, real scalar n,
    real scalar b0, real colvector ylag)
{
    real scalar s2, tk, val
    s2 = cross(e,e)/n
    if (ic==1)      val = log(s2) + k*2/n
    else if (ic==2) val = log(s2) + k*log(n)/n
    else {
        tk = cross(ylag,ylag)*(b0*b0)/s2
        if (ic==3) val = log(s2) + (k+tk)*2/n
        else       val = log(s2) + (k+tk)*log(n)/n
    }
    return(val)
}

// first & last non-missing row of a column (assumes no internal gaps)
real rowvector bu_range(real colvector x)
{
    real colvector idx
    idx = selectindex(x:!=.)
    return( (idx[1], idx[rows(idx)]) )
}

// 1 if any series has an internal missing (a gap inside its observed span)
real scalar bu_check_missing(string scalar vlist, string scalar touse)
{
    real matrix Y
    real scalar N, iN, bad
    real colvector idx
    Y = st_data(., vlist, touse)
    N = cols(Y)
    bad = 0
    for (iN=1; iN<=N; iN++) {
        idx = selectindex(Y[.,iN]:!=.)
        if (rows(idx) >= 2) {
            if ( max(idx[|2\rows(idx)|] - idx[|1\rows(idx)-1|]) != 1 ) bad = 1
        }
    }
    return(bad)
}

// 1 if all series share the same non-missing first/last observation
real scalar bu_all_balanced(string scalar vlist, string scalar touse)
{
    real matrix Y, rng
    real scalar N, iN
    Y = st_data(., vlist, touse)
    N = cols(Y)
    rng = J(2,N,0)
    for (iN=1; iN<=N; iN++) rng[.,iN] = bu_range(Y[.,iN])'
    return( (max(rng[1,.])==min(rng[1,.])) & (max(rng[2,.])==min(rng[2,.])) )
}

real scalar bu_argmin(real colvector v)
{
    real scalar i, mi, mv
    mv = v[1]; mi = 1
    for (i=2; i<=rows(v); i++) {
        if (v[i] < mv) {
            mv = v[i]
            mi = i
        }
    }
    return(mi)
}

//-------------------------------------------------------------------------------
// two-step lag selection.  Faithful port of adf_selectlags_cpp().
//-------------------------------------------------------------------------------
struct bu_adf scalar bu_selectlags(real colvector y, real scalar pmin,
    real scalar pmax, real scalar ic, real scalar dc, real scalar QD,
    real scalar ic_scale, real scalar h_rs, real scalar trim)
{
    real scalar n, ip, popt
    real colvector ys, ylag, icv
    struct bu_adf scalar adfp
    n = rows(y)
    ys = y
    if (ic_scale) ys = bu_rescale(y, h_rs, 0, dc, 0, 1, 0)
    ylag = bu_detrend(ys, dc, 0)[|(pmax+2) \ (n-1)|]
    icv = J(pmax-pmin+1, 1, 0)
    for (ip=pmin; ip<=pmax; ip++) {
        adfp = bu_adf_fit(ys, ip, dc, 0, trim, pmax)
        icv[ip-pmin+1] = bu_ic(ic, adfp.res[|(pmax+2) \ n|], ip, n-pmax-1,
            adfp.par[1], ylag)
    }
    popt = bu_argmin(icv) - 1 + pmin
    return( bu_adf_fit(y, popt, dc, QD, trim, 0) )
}

//===============================================================================
// One-step ADF (used only by adf, two_step=FALSE)
//===============================================================================
struct bu_adf scalar bu_adf1_fit(real colvector z, real scalar p, real scalar dc,
    real scalar trim, real scalar trim_ic)
{
    real scalar n, i, trim_t, s2
    real colvector y, ylag, ydif, b, e, els, yls
    real matrix X, xxi, xls, d
    struct bu_adf scalar out

    n    = rows(z)
    y    = bu_detrend(z, 0, 0)          // no detrending of y
    ylag = J(n,1,0); ylag[|2 \ n|] = y[|1 \ n-1|]
    ydif = y - ylag
    if (p>0) X = ylag , bu_lagmat(ydif, p, 0)
    else     X = ylag
    if (dc>0) {
        d = J(n,dc,0)
        for (i=0; i<=dc-1; i++) d[.,i+1] = (1::n):^i
        X = X , d
    }
    if (trim_ic==0) trim_t = p
    else            trim_t = trim_ic
    if (trim) {
        xls = X[|(trim_t+2),1 \ n, cols(X)|]
        yls = ydif[|(trim_t+2) \ n|]
    }
    else {
        xls = X; yls = ydif
    }
    xxi = invsym(cross(xls,xls))
    b   = xxi * cross(xls,yls)
    e   = ydif - X*b
    els = e[|(trim_t+2) \ n|]
    s2  = cross(els,els)/rows(els)
    out.t    = b[1]/sqrt(s2*xxi[1,1])
    out.c    = n*b[1]/(1 - sum(b) + b[1])
    out.par  = b
    out.res  = e
    out.bres = e
    return(out)
}

real colvector bu_rescale1(real colvector y, real scalar h, real scalar p,
    real scalar dc, real scalar trim, real scalar trim_ic)
{
    struct bu_adf scalar fit
    real colvector u, ydif, shat
    fit  = bu_adf1_fit(y, p, dc, trim, trim_ic)
    u    = fit.res
    ydif = bu_diffv(y, 0, 1)
    shat = sqrt(bu_npve(u, h))
    return( runningsum(ydif:/shat) )
}

struct bu_adf scalar bu_selectlags1(real colvector y, real scalar pmin,
    real scalar pmax, real scalar ic, real scalar dc, real scalar ic_scale,
    real scalar h_rs, real scalar trim)
{
    real scalar n, ip, popt
    real colvector ys, ylag, icv
    struct bu_adf scalar adfp
    n = rows(y)
    ys = y
    if (ic_scale) ys = bu_rescale1(y, h_rs, 0, dc, 1, 0)
    ylag = bu_detrend(ys, 0, 0)[|(pmax+2) \ (n-1)|]
    icv = J(pmax-pmin+1, 1, 0)
    for (ip=pmin; ip<=pmax; ip++) {
        adfp = bu_adf1_fit(ys, ip, dc, trim, pmax)
        icv[ip-pmin+1] = bu_ic(ic, adfp.res[|(pmax+2) \ n|], ip, n-pmax-1,
            adfp.par[1], ylag)
    }
    popt = bu_argmin(icv) - 1 + pmin
    return( bu_adf1_fit(y, popt, dc, trim, 0) )
}

//-------------------------------------------------------------------------------
// validation harness: one series, one spec
//-------------------------------------------------------------------------------
void _bu_check_one(string scalar var, string scalar touse, real scalar dc,
    real scalar ic, real scalar scale, real scalar two, real scalar pmin,
    real scalar pmax, real scalar qd, string scalar gnm, string scalar tnm,
    string scalar lnm)
{
    real colvector y, ys, ylag, icv
    real scalar n, ip, pols
    real rowvector rg
    struct bu_adf scalar f, adfp
    y = st_data(., var, touse)
    rg = bu_range(y)
    y = y[|rg[1] \ rg[2]|]
    if (qd) {
        // union assembly: select lag under OLS, refit under QD at that lag
        f    = bu_selectlags(y, pmin, pmax, ic, dc, 0, scale, 0.1, 1)
        pols = rows(f.par)-1
        f    = bu_adf_fit(y, pols, dc, 1, 1, 0)
    }
    else if (two) f = bu_selectlags(y, pmin, pmax, ic, dc, 0, scale, 0.1, 1)
    else          f = bu_selectlags1(y, pmin, pmax, ic, dc, scale, 0.1, 1)
    st_numscalar(gnm, f.par[1])
    st_numscalar(tnm, f.t)
    st_numscalar(lnm, rows(f.par)-1)
    // diagnostic: dump two-step IC vector + rescale internals
    if (two) {
        real colvector u0, ydif0, shat0
        struct bu_adf scalar f0
        n = rows(y)
        ys = y
        if (scale) {
            f0    = bu_adf_fit(y, 0, dc, 0, 1, 0)
            u0    = f0.res
            ydif0 = bu_diffv(y, 0, 1)
            shat0 = sqrt(bu_npve(u0, 0.1))
            st_local("shmin", strofreal(colmin(shat0), "%12.6g"))
            st_local("umiss", strofreal(missing(u0)))
            ys = runningsum(ydif0:/shat0)
            st_local("ysmiss", strofreal(missing(ys)))
        }
        ylag = bu_detrend(ys, dc, 0)[|(pmax+2) \ (n-1)|]
        icv = J(pmax-pmin+1, 1, 0)
        for (ip=pmin; ip<=pmax; ip++) {
            adfp = bu_adf_fit(ys, ip, dc, 0, 1, pmax)
            icv[ip-pmin+1] = bu_ic(ic, adfp.res[|(pmax+2) \ n|], ip, n-pmax-1,
                adfp.par[1], ylag)
        }
        st_local("icvec", invtokens(strofreal(icv', "%10.5g")))
    }
}

//===============================================================================
// BOOTSTRAP ENGINE
//===============================================================================

// Observed ADF test statistics / parameter estimates / lags for all N series
// over the D = |dc|*|detr| deterministic-detrending combinations, in the R
// ordering: [OLS/dc1, OLS/dc2, ..., QD/dc1, QD/dc2, ...].  trim = 1.
//   returns nothing; fills tests (D x N), par (D x N), lags (D x N) by ref
void bu_tests_panel(real matrix Y, real matrix rng, real scalar pmin,
    real scalar pmax, real scalar ic, real rowvector dcv, real rowvector detrv,
    real scalar ic_scale, real scalar h_rs, real matrix tests, real matrix par,
    real matrix lags)
{
    real scalar N, nd, iN, idc, hasOLS, hasQD, p_ols, rr
    real colvector y
    struct bu_adf scalar fO, fQ
    real matrix tO, tQ, pO, pQ, lO
    N  = cols(Y)
    nd = cols(dcv)
    hasOLS = anyof(detrv, 1)
    hasQD  = anyof(detrv, 2)
    tO = J(nd, N, 0); pO = J(nd, N, 0); lO = J(nd, N, 0)
    tQ = J(nd, N, 0); pQ = J(nd, N, 0)
    for (iN=1; iN<=N; iN++) {
        y = Y[|rng[1,iN], iN \ rng[2,iN], iN|]
        for (idc=1; idc<=nd; idc++) {
            if (hasOLS) {
                fO = bu_selectlags(y, pmin, pmax, ic, dcv[idc], 0, ic_scale, h_rs, 1)
                tO[idc,iN] = fO.t
                pO[idc,iN] = fO.par[1]
                lO[idc,iN] = rows(fO.par)-1
                if (hasQD) {
                    p_ols = rows(fO.par)-1
                    fQ = bu_adf_fit(y, p_ols, dcv[idc], 1, 1, 0)
                    tQ[idc,iN] = fQ.t
                    pQ[idc,iN] = fQ.par[1]
                }
            }
            else {   // QD only
                fQ = bu_selectlags(y, pmin, pmax, ic, dcv[idc], 1, ic_scale, h_rs, 1)
                tQ[idc,iN] = fQ.t
                pQ[idc,iN] = fQ.par[1]
                lO[idc,iN] = rows(fQ.par)-1
            }
        }
    }
    if (hasOLS & hasQD) {
        tests = tO \ tQ ; par = pO \ pQ ; lags = lO \ lO
    }
    else if (hasOLS) {
        tests = tO ; par = pO ; lags = lO
    }
    else {
        tests = tQ ; par = pQ ; lags = lO
    }
}

// Observed statistics for a single bootstrap pseudo-panel y_star (D x N -> row)
real rowvector bu_tests_star(real matrix Y, real matrix rng, real scalar pmin,
    real scalar pmax, real scalar ic, real rowvector dcv, real rowvector detrv,
    real scalar ic_scale, real scalar h_rs)
{
    real matrix tests, par, lags
    bu_tests_panel(Y, rng, pmin, pmax, ic, dcv, detrv, ic_scale, h_rs,
        tests, par, lags)
    return( vec(tests)' )     // column-major: series-blocks of D
}

// DGP fit: residuals eb (restricted) and e (full), AR coefficients, per series.
// Uses QD=0, trim=0, dc = dc_boot.  Fills u (T x N eb), e (T x N), arest
// (pmax x N) by reference; zeros outside the non-missing range.
void bu_dgp_panel(real matrix Y, real matrix rng, real scalar pmin,
    real scalar pmax, real scalar ic, real scalar dc_boot, real scalar ic_scale,
    real scalar h_rs, real matrix u, real matrix e, real matrix arest)
{
    real scalar T, N, iN, p, a, b
    real colvector y
    struct bu_adf scalar f
    T = rows(Y); N = cols(Y)
    u = J(T, N, 0); e = J(T, N, 0); arest = J(pmax, N, 0)
    for (iN=1; iN<=N; iN++) {
        a = rng[1,iN] ; b = rng[2,iN]
        y = Y[|a, iN \ b, iN|]
        f = bu_selectlags(y, pmin, pmax, ic, dc_boot, 0, ic_scale, h_rs, 0)
        p = rows(f.par)-1
        u[|a, iN \ b, iN|] = f.bres
        e[|a, iN \ b, iN|] = f.res
        if (p>=1) arest[|1, iN \ p, iN|] = f.par[|2 \ p+1|]
    }
}

// AR(1)-driven wild sequence for AWB (returns rows(x)+1 values incl. the init)
real colvector bu_genAR1(real colvector x, real scalar ar, real scalar init)
{
    real scalar m, t
    real colvector y
    m = rows(x)
    y = J(m+1,1,0)
    y[1] = init
    for (t=2; t<=m+1; t++) y[t] = x[t-1] + ar*y[t-1]
    return(y)
}

// AR(p) recursion for the sieve (init zeros, x length T -> output length T)
real colvector bu_genARp(real colvector x, real colvector ar)
{
    real scalar T, p, t, j, s
    real colvector y, arr
    T = rows(x)
    p = rows(ar)
    arr = ar[p::1]                 // reversed
    y = J(T+p, 1, 0)
    for (t=p+1; t<=T+p; t++) {
        s = x[t-p]
        for (j=1; j<=p; j++) s = s + arr[j]*y[t-p+j-1]
        y[t] = s
    }
    return( y[|p+1 \ T+p|] )
}

// trapezoid window and self-convolution for the DWB weight matrix
real scalar bu_wtrap(real scalar x, real scalar c)
{
    real scalar y
    y = 0
    if (x>=0 & x<c)          y = x/c
    else if (x>=c & x<=1-c)  y = 1
    else if (x>1-c & x<=1)   y = (1-x)/c
    return(y)
}
real scalar bu_selfconv(real scalar t, real scalar c, real scalar ngrid)
{
    real scalar a, bnd, h, i, x, s, at
    at = abs(t)
    a = -1 ; bnd = 1
    h = (bnd-a)/ngrid
    s = 0
    for (i=0; i<=ngrid; i++) {
        x = a + i*h
        real scalar w
        w = bu_wtrap(x,c)*bu_wtrap(x+at,c)
        if (i==0 | i==ngrid) s = s + 0.5*w
        else                 s = s + w
    }
    return(s*h)
}
real matrix bu_dwb_s(real scalar T, real scalar l)
{
    real scalar i, j, denom, c, ng
    real colvector cv, eval
    real matrix m, evec, s
    c = 0.43 ; ng = 1000
    denom = bu_selfconv(0, c, ng)
    cv = J(2*T-1, 1, 0)            // self-conv for lags -(T-1)..(T-1)
    for (i=1; i<=2*T-1; i++) cv[i] = bu_selfconv((i-T)/l, c, ng)/denom
    m = J(T,T,0)
    for (i=1; i<=T; i++) {
        for (j=1; j<=T; j++) m[i,j] = cv[(i-j)+T]
    }
    symeigensystem(m, evec, eval)
    eval = eval'
    for (i=1; i<=T; i++) {
        if (eval[i] <= 1e-10) eval[i] = 1e-10
    }
    // sign-normalise eigenvectors by the sign of their first element
    for (j=1; j<=T; j++) {
        if (evec[1,j] < 0) evec[.,j] = -evec[.,j]
    }
    s = evec * diag(sqrt(eval))
    return(s)
}

// column-wise cumulative sum of a matrix
real matrix bu_colcumsum(real matrix X)
{
    real scalar n, j
    real matrix Y
    n = rows(X)
    Y = X
    for (j=2; j<=n; j++) Y[j,.] = Y[j-1,.] + X[j,.]
    return(Y)
}

// One bootstrap pseudo-panel y_star (T x N) for a given method boot=1..6
real matrix bu_boot_dgp(real scalar boot, real matrix u, real matrix e,
    real colvector z, real colvector iidx, real scalar l, real matrix sD,
    real scalar ar, real matrix arest)
{
    real scalar T, N, nb, iN, bnum, t
    real matrix ustar, ystar, xirep
    real colvector xi, zi, ecol
    T = rows(u) ; N = cols(u)
    if (boot==1) {                                   // MBB
        nb = ceil(T/l)
        ustar = J(nb*l+1, N, 0)
        for (bnum=1; bnum<=nb; bnum++) {
            ustar[|(bnum-1)*l+2, 1 \ (bnum-1)*l+1+l, N|] =
                u[|iidx[bnum], 1 \ iidx[bnum]+l-1, N|]
        }
        ystar = bu_colcumsum(ustar)
        return( ystar[|rows(ystar)-T+1, 1 \ rows(ystar), N|] )
    }
    else if (boot==2) {                              // BWB
        nb = ceil(T/l)
        xi = J(nb*l, 1, 0)
        for (bnum=1; bnum<=nb; bnum++) xi[|(bnum-1)*l+1 \ bnum*l|] = J(l,1,z[bnum])
        xirep = xi[|1 \ T|] * J(1,N,1)
        ustar = J(1,N,0) \ (u :* xirep)
        ystar = bu_colcumsum(ustar)
        return( ystar[|2, 1 \ T+1, N|] )
    }
    else if (boot==3) {                              // DWB
        xi = sD * z[|1 \ T|]
        xirep = xi * J(1,N,1)
        ustar = J(1,N,0) \ (u :* xirep)
        ystar = bu_colcumsum(ustar)
        return( ystar[|2, 1 \ T+1, N|] )
    }
    else if (boot==4) {                              // AWB
        zi = z[|2 \ T|] * sqrt(1-ar*ar)
        xi = bu_genAR1(zi, ar, z[1])
        xirep = xi * J(1,N,1)
        ustar = J(1,N,0) \ (u :* xirep)
        ystar = bu_colcumsum(ustar)
        return( ystar[|2, 1 \ T+1, N|] )
    }
    else if (boot==5) {                              // SB
        real matrix estar
        estar = e[iidx[|1 \ T|], .]
        ustar = J(T, N, 0)
        for (iN=1; iN<=N; iN++) ustar[.,iN] = bu_genARp(estar[.,iN], arest[.,iN])
        ustar = J(1,N,0) \ ustar
        ystar = bu_colcumsum(ustar)
        return( ystar[|2, 1 \ T+1, N|] )
    }
    else {                                           // SWB (boot==6)
        real matrix es2
        es2 = (z * J(1,N,1)) :* e
        ustar = J(T, N, 0)
        for (iN=1; iN<=N; iN++) ustar[.,iN] = bu_genARp(es2[.,iN], arest[.,iN])
        ustar = J(1,N,0) \ ustar
        ystar = bu_colcumsum(ustar)
        return( ystar[|2, 1 \ T+1, N|] )
    }
}

// Full bootstrap loop -> t_star (B x (D*N)).  rng0 is the range used for the
// star tests (1..T for every column, since y_star is balanced when joint).
real matrix bu_bootstrap(real scalar B, real scalar boot, real matrix u,
    real matrix e, real scalar l, real matrix sD, real scalar ar, real matrix arest,
    real scalar pmin, real scalar pmax, real scalar ic, real rowvector dcv,
    real rowvector detrv, real scalar ic_scale, real scalar h_rs, real matrix rng,
    real scalar joint, real scalar showdots)
{
    real scalar T, N, D, ub, iB, iN, step
    real matrix z, iidx, tstar, ystar, rng1
    real rowvector rr
    T = rows(u) ; N = cols(u)
    D = cols(dcv)*cols(detrv)
    if (boot==6) ub = 1
    else         ub = l
    z    = rnormal(T, B, 0, 1)
    iidx = ceil(runiform(T, B) :* (T-ub+1))
    tstar = J(B, D*N, 0)
    step = max((1, floor(B/40)))
    if (joint) {
        for (iB=1; iB<=B; iB++) {
            ystar = bu_boot_dgp(boot, u, e, z[.,iB], iidx[.,iB], l, sD, ar, arest)
            tstar[iB,.] = bu_tests_star(ystar, rng, pmin, pmax, ic, dcv, detrv,
                ic_scale, h_rs)
            if (showdots & mod(iB,step)==0) printf(".")
        }
    }
    else {
        for (iB=1; iB<=B; iB++) {
            for (iN=1; iN<=N; iN++) {
                ystar = bu_boot_dgp(boot, u[.,iN], e[.,iN], z[.,iB], iidx[.,iB],
                    l, sD, ar, arest[.,iN])
                rng1 = (1 \ rows(ystar))
                rr = bu_tests_star(ystar, rng1, pmin, pmax, ic, dcv, detrv,
                    ic_scale, h_rs)
                tstar[|iB, (iN-1)*D+1 \ iB, iN*D|] = rr
            }
            if (showdots & mod(iB,step)==0) printf(".")
        }
    }
    if (showdots) displayflush()
    return(tstar)
}

// individual bootstrap p-values: P*(t* < t_obs) per column
real colvector bu_iadf(real rowvector testi, real matrix tstar)
{
    real scalar M, j, B
    real colvector pv
    M = cols(testi) ; B = rows(tstar)
    pv = J(M,1,0)
    for (j=1; j<=M; j++) pv[j] = sum(tstar[.,j] :< testi[j]) / B
    return(pv)
}

// union scaling factors: prob-quantile of each series' D bootstrap columns
real matrix bu_scaling(real matrix tstar, real scalar D, real scalar prob)
{
    real scalar N, iN, B, k
    real matrix sc, sub
    real colvector col
    N = cols(tstar)/D ; B = rows(tstar)
    sc = J(D, N, 0)
    k = ceil(prob*B)
    if (k<1) k = 1
    for (iN=1; iN<=N; iN++) {
        sub = tstar[|1,(iN-1)*D+1 \ B,iN*D|]
        for (col=1; col<=D; col++) {
            real colvector v
            v = sort(sub[.,col],1)
            sc[col,iN] = v[k]
        }
    }
    return(sc)
}

// union statistics: min over D of (-t / scaling), for a B x (D*N) matrix
real matrix bu_union(real matrix t, real scalar D, real matrix s)
{
    real scalar B, N, iB, iN
    real matrix ut, block
    B = rows(t) ; N = cols(t)/D
    ut = J(B, N, 0)
    for (iB=1; iB<=B; iB++) {
        for (iN=1; iN<=N; iN++) {
            block = t[|iB,(iN-1)*D+1 \ iB,iN*D|]'   // D x 1
            ut[iB,iN] = colmin( (-block) :/ s[.,iN] )
        }
    }
    return(ut)
}
// union statistic for a single observed row (1 x D) with scaling (D x 1)
real scalar bu_union1(real rowvector t, real colvector s)
{
    return( colmin( (-t') :/ s ) )
}

// k-th smallest value in a row vector
real scalar bu_ksmall(real rowvector v, real scalar k)
{
    real rowvector sv
    sv = sort(v', 1)'
    return(sv[k])
}

// one BSQT step -> (p0, p1, index_j, test_j, pval_j)
real rowvector bu_bsqt_step(real scalar p0, real scalar p1, real rowvector testi,
    real colvector ranks, real matrix tstar, real scalar N)
{
    real scalar index_j, test_j, i, B, k, cnt
    real colvector ind
    real matrix tsub
    ind  = sort(ranks[|p0+1 \ N|], 1)
    tsub = tstar[., ind]
    index_j = ranks[p1]
    test_j  = testi[index_j]
    B = rows(tsub)
    k = p1 - p0
    cnt = 0
    for (i=1; i<=B; i++) {
        if (bu_ksmall(tsub[i,.], k) < test_j) cnt = cnt + 1
    }
    return( (p0, p1, index_j, test_j, cnt/B) )
}

// BSQT sequential test.  Posts rej (N x 1) and the step matrix.
void bu_bsqt(real colvector pvec, real rowvector testi, real matrix tstar,
    real scalar level, string scalar rejnm, string scalar seqnm)
{
    real scalar N, K, phat, i, nstep
    real colvector ranks, rej
    real matrix steps
    N = cols(testi)
    ranks = order(testi', 1)
    K = rows(pvec)-1
    phat = N
    nstep = K
    steps = J(K,5,0)
    for (i=1; i<=K; i++) {
        steps[i,.] = bu_bsqt_step(pvec[i], pvec[i+1], testi, ranks, tstar, N)
        if (steps[i,5] > level) {
            phat = steps[i,1]
            nstep = i
            i = K + 1
        }
    }
    steps = steps[|1,1 \ nstep,5|]
    rej = J(N,1,0)
    if (phat > 0) rej[ranks[|1 \ phat|]] = J(phat,1,1)
    st_matrix(rejnm, rej)
    st_matrix(seqnm, steps)
}

// FDR step-down (Moon-Perron / Romano-Shaikh-Wolf).  Faithful port of FDR_cpp.
void bu_fdr(real rowvector testi, real matrix tstar, real scalar level,
    string scalar rejnm, string scalar seqnm)
{
    real scalar N, B, j, no_r, phat, pos, r, a, cc, pseudo, mrow
    real colvector ranks, cvfdr, rej, FDRest, cum, cmp, rj, rc1
    real matrix tsub, sorted, cvstar, norej, norej_jp, seq
    N = cols(testi)
    B = rows(tstar)
    ranks = order(testi', 1)
    pseudo = 1e300
    cvfdr = J(N,1,0)

    for (j=0; j<=N-1; j++) {
        tsub = tstar[., ranks[|N-j \ N|]]              // B x (j+1)
        sorted = J(B, j+1, 0)
        for (r=1; r<=B; r++) sorted[r,.] = sort(tsub[r,.]', 1)'
        rc1 = order(sorted[.,1], 1)
        cvstar = sorted[rc1,.] \ J(1, j+1, pseudo)     // (B+1) x (j+1)

        if (j==0) {
            pos = min((B, floor(N*level*B)))
            if (N*level <= 1) pos = pos - 1
            cvfdr[N] = cvstar[pos+1, 1]                 // C++ 0-based -> +1
        }
        else if (j < N-1) {
            norej_jp = J(B+1, j, 1)
            for (a=1; a<=B+1; a++) {
                for (cc=1; cc<=j; cc++) {
                    if (cvstar[a, cc+1] <= cvfdr[N-j+cc]) norej_jp[a,cc] = 0
                }
            }
            norej_jp = norej_jp , J(B+1,1,1)
            norej = J(B+1, j+1, 1)
            norej[.,1] = norej_jp[.,1]
            FDRest = bu_rowprod(norej) / (N - j)
            for (no_r=1; no_r<=j; no_r++) {
                norej[.,no_r]   = J(B+1,1,1) - norej[.,no_r]
                norej[.,no_r+1] = norej_jp[.,no_r+1]
                FDRest = FDRest + (no_r+1) * bu_rowprod(norej) / (N - j + no_r)
            }
            cum = runningsum(FDRest / B)
            pos = sum(cum :<= level)
            cvfdr[N-j] = cvstar[pos, 1]
        }
        else {
            cvfdr[1] = cvstar[floor(level*B), 1]
        }
    }

    // rejections: cumulative product of (test_i(ranks) < cvfdr), scattered back
    cmp = (testi[ranks]' :< cvfdr)
    rj  = bu_cumprod(cmp)
    rej = J(N,1,0)
    rej[ranks] = rj
    phat = sum(rej)

    mrow = min((N, phat+1))
    seq = J(mrow, 3, 0)
    for (j=1; j<=mrow; j++) {
        seq[j,1] = ranks[j]
        seq[j,2] = testi[ranks[j]]
        seq[j,3] = cvfdr[j]
    }
    st_matrix(rejnm, rej)
    st_matrix(seqnm, seq)
}
real colvector bu_rowprod(real matrix X)
{
    real scalar n, m, i, j
    real colvector p
    n = rows(X) ; m = cols(X)
    p = J(n,1,1)
    for (i=1; i<=n; i++) {
        for (j=1; j<=m; j++) p[i] = p[i]*X[i,j]
    }
    return(p)
}
real colvector bu_cumprod(real colvector v)
{
    real scalar n, i
    real colvector p
    n = rows(v)
    p = J(n,1,0)
    p[1] = v[1]
    for (i=2; i<=n; i++) p[i] = p[i-1]*v[i]
    return(p)
}

//===============================================================================
// MAIN DRIVER for boot_ur / boot_fdr / boot_sqt / boot_panel
//===============================================================================
//  opt = (boot,B,l,arAWB,ic,ic_scale,h_rs,pmin,pmax,union,dc,detr,level,joint,mode)
//  mode: 1=ur, 2=fdr, 3=sqt, 4=panel
void bu_run(string scalar vlist, string scalar touse, real rowvector opt,
    string scalar pvecnm)
{
    real scalar boot, B, l, arAWB, ic, ic_scale, h_rs, pmin, pmax, uni
    real scalar dc1, detr1, level, joint, mode, T, N, D, dc_boot, iN, showdots
    real matrix Y, rng, tests, par, lags, tstar, sD, u, e, arest, ustar
    real matrix sc, pind
    real rowvector dcv, detrv, uobs
    real colvector pv, est, stat, pvalc, gm_star
    real scalar gm, gmp

    boot=opt[1]; B=opt[2]; l=opt[3]; arAWB=opt[4]; ic=opt[5]; ic_scale=opt[6]
    h_rs=opt[7]; pmin=opt[8]; pmax=opt[9]; uni=opt[10]; dc1=opt[11]; detr1=opt[12]
    level=opt[13]; joint=opt[14]; mode=opt[15]; showdots=opt[16]

    Y = st_data(., vlist, touse)
    T = rows(Y); N = cols(Y)
    rng = J(2,N,0)
    for (iN=1; iN<=N; iN++) rng[.,iN] = bu_range(Y[.,iN])'

    if (uni) {
        dcv = (1,2); detrv = (1,2); dc_boot = 2
    }
    else {
        dcv = (dc1); detrv = (detr1); dc_boot = dc1
    }
    D = cols(dcv)*cols(detrv)

    if (boot==3) sD = bu_dwb_s(T, l)
    else         sD = J(1,1,0)

    bu_tests_panel(Y, rng, pmin, pmax, ic, dcv, detrv, ic_scale, h_rs, tests, par, lags)
    bu_dgp_panel(Y, rng, pmin, pmax, ic, dc_boot, ic_scale, h_rs, u, e, arest)
    tstar = bu_bootstrap(B, boot, u, e, l, sD, arAWB, arest, pmin, pmax, ic,
        dcv, detrv, ic_scale, h_rs, rng, joint, showdots)

    // individual (per-combination) p-values, reshaped to N x D
    pv = bu_iadf(vec(tests)', tstar)
    pind = rowshape(pv, N)

    // observed statistic & estimate to report at series level
    est  = J(N,1,.)
    stat = J(N,1,0)
    pvalc = J(N,1,.)

    if (uni) {
        sc = bu_scaling(tstar, D, level)
        ustar = bu_union(tstar, D, sc)               // B x N
        uobs = J(1,N,0)
        for (iN=1; iN<=N; iN++) uobs[iN] = bu_union1(tests[.,iN]', sc[.,iN])
        stat = uobs'
        // estimate stays missing for union
    }
    else {
        stat = tests[1,.]'
        est  = par[1,.]'
    }

    if (mode==1) {               // ur
        if (uni) pvalc = bu_iadf(uobs, ustar)
        else     pvalc = bu_iadf(tests[1,.], tstar)
    }
    else if (mode==2) {          // fdr
        if (uni) bu_fdr(uobs, ustar, level, "__bu_rej", "__bu_seq")
        else     bu_fdr(tests[1,.], tstar, level, "__bu_rej", "__bu_seq")
    }
    else if (mode==3) {          // sqt
        real colvector pvec
        pvec = st_matrix(pvecnm)'
        if (uni) bu_bsqt(pvec, uobs, ustar, level, "__bu_rej", "__bu_seq")
        else     bu_bsqt(pvec, tests[1,.], tstar, level, "__bu_rej", "__bu_seq")
    }
    else {                       // panel group-mean
        if (uni) {
            gm = mean(uobs')
            gm_star = bu_rowmean(ustar)
        }
        else {
            gm = mean(tests[1,.]')
            gm_star = bu_rowmean(tstar)
        }
        gmp = sum(gm_star :< gm)/B
        st_numscalar("__bu_gm", gm)
        st_numscalar("__bu_gmp", gmp)
    }

    // post everything for the ado to format
    st_matrix("__bu_est",  est)
    st_matrix("__bu_stat", stat)
    st_matrix("__bu_pval", pvalc)
    st_matrix("__bu_dstat", tests')      // N x D individual statistics
    st_matrix("__bu_dpar",  par')        // N x D individual estimates
    st_matrix("__bu_dlag",  lags')       // N x D individual lags
    st_matrix("__bu_dpval", pind)        // N x D individual p-values
    st_numscalar("__bu_D", D)
    st_numscalar("__bu_N", N)
    st_numscalar("__bu_jointused", joint)
}
real colvector bu_rowmean(real matrix X)
{
    return( rowsum(X)/cols(X) )
}

// difference a column d times (row order), leaving d leading missings
real colvector bu_ndiff(real colvector y, real scalar d)
{
    real scalar k, t, n
    real colvector x, nx
    x = y
    for (k=1; k<=d; k++) {
        n = rows(x)
        nx = J(n,1,.)
        for (t=2; t<=n; t++) nx[t] = x[t] - x[t-1]
        x = nx
    }
    return(x)
}
void bu_diff_store(string scalar vin, string scalar vout, string scalar touse,
    real scalar d)
{
    real colvector y, dd, idx
    y   = st_data(., vin, touse)
    dd  = bu_ndiff(y, d)
    idx = selectindex(st_data(., touse):!=0)
    st_store(idx, st_varindex(vout), dd)
}

// build a missing-value classification map (types 1..4) as (T*N) x 3
void bu_missmap(string scalar vlist, string scalar matname)
{
    real matrix Y, rng, out
    real scalar T, N, iN, t, minidx, maxidx, r, ty
    Y = st_data(., vlist)
    T = rows(Y); N = cols(Y)
    rng = J(2,N,0)
    for (iN=1; iN<=N; iN++) rng[.,iN] = bu_range(Y[.,iN])'
    minidx = min(rng[1,.]); maxidx = max(rng[2,.])
    out = J(T*N, 3, 0)
    r = 0
    for (iN=1; iN<=N; iN++) {
        for (t=1; t<=T; t++) {
            r = r + 1
            out[r,1] = iN
            out[r,2] = T - t + 1        // so obs 1 plots at the top
            ty = 1
            if (t < minidx | t > maxidx) ty = 2
            else if (Y[t,iN]==.) {
                if (t > rng[1,iN] & t < rng[2,iN]) ty = 4
                else                                ty = 3
            }
            out[r,3] = ty
        }
    }
    st_matrix(matname, out)
}

// asymptotic ADF for a single series -> gamma, tstat, lag, effective TT
void bu_adf_run(string scalar vlist, string scalar touse, real scalar dc,
    real scalar ic, real scalar scale, real scalar two, real scalar pmin,
    real scalar pmax, string scalar gnm, string scalar tnm, string scalar lnm,
    string scalar ttnm)
{
    real colvector y
    real rowvector rg
    struct bu_adf scalar f
    y  = st_data(., vlist, touse)
    rg = bu_range(y)
    y  = y[|rg[1] \ rg[2]|]
    if (two) f = bu_selectlags(y, pmin, pmax, ic, dc, 0, scale, 0.1, 1)
    else     f = bu_selectlags1(y, pmin, pmax, ic, dc, scale, 0.1, 1)
    st_numscalar(gnm, f.par[1])
    st_numscalar(tnm, f.t)
    st_numscalar(lnm, rows(f.par)-1)
    st_numscalar(ttnm, rows(y))
}

// <<<BEGIN MACKINNON>>>
// ==== MacKinnon (1996) unit-root p-value response surfaces (from urca) ====
// (raw Mata snippet, injected into bootur.ado's engine block)
real matrix bu_urc_nc()
{
    string scalar s
    real rowvector v
    s = ""
    s = s + " -3.8929681 -10.711437 -55.619955 0.0033188192 -3.7185872 -9.5896921 -34.166532 0.0024951489 -3.4759164 -7.8746051 -17.490657 0.0015559156 -3.2842708 -6.4108912 -11.983755 0.0011445964 -3.0830457 -5.0567633 -6.8847143 0.00084100765 -2.9598602 -4.2584716 -5.8142463 0.00071049934 -2.8698825 -3.728955 -5.8714971 0.00062391151 -2.7977077 -3.4146427 -3.76153 0.00058693244 -2.738005 -3.1208498 -3.0462883 0.00052576407 -2.6868436 -2.8722476 -2.5438563 0.00049052976"
    s = s + " -2.6416852 -2.6793402 -1.8769783 0.00046804316 -2.6012597 -2.5000004 -1.6307933 0.00044346134 -2.5649446 -2.3127399 -2.0306605 0.00043039003 -2.4206178 -1.7291886 -1.3466493 0.00036467475 -2.3133304 -1.3423615 -1.3432257 0.00032107164 -2.2273143 -1.0746264 -0.8762427 0.00029789755 -2.1549047 -0.84657628 -1.0780188 0.00027830583 -2.0921655 -0.67744316 -1.0430697 0.00026027602 -2.0364584 -0.54192487 -0.96965194 0.00025249134 -1.9864146 -0.4161689 -1.1334045 0.00024079995"
    s = s + " -1.9407684 -0.33025231 -0.67821426 0.00023323022 -1.8988585 -0.22970773 -0.85640849 0.00022075141 -1.8598488 -0.14639728 -1.0428806 0.00021334955 -1.8233573 -0.089663803 -0.80855945 0.0002096301 -1.7891398 -0.036466865 -0.63243896 0.00020834232 -1.7567993 0.011402654 -0.51066497 0.00020539933 -1.7262105 0.066220956 -0.63708003 0.00019964762 -1.6969838 0.10236824 -0.46672787 0.00019574132 -1.6690859 0.14265332 -0.45061418 0.00018888062 -1.6424271 0.18701823 -0.66084335 0.00018426555"
    s = s + " -1.6167279 0.21626789 -0.64616991 0.00018128089 -1.592052 0.24778988 -0.63597502 0.00017954902 -1.5682114 0.27323562 -0.61618157 0.00017773495 -1.545274 0.29991006 -0.60544565 0.00017142168 -1.5230643 0.33148333 -0.76580637 0.00016769202 -1.5014865 0.35136387 -0.69024691 0.00016887147 -1.48057 0.37478667 -0.72930388 0.00016872218 -1.4602522 0.39420657 -0.70443601 0.00016401731 -1.4404242 0.41028681 -0.64338518 0.00016224607 -1.4210785 0.421192 -0.555484 0.00016193196"
    s = s + " -1.4022406 0.43747746 -0.5767082 0.00016097849 -1.3837876 0.44575298 -0.43236279 0.00015803832 -1.3657717 0.45528883 -0.35165569 0.00015694908 -1.3481032 0.46306181 -0.31093184 0.00015603528 -1.3309144 0.47972473 -0.3912126 0.00015557033 -1.3139547 0.48814175 -0.38006723 0.00015236727 -1.2973931 0.49859437 -0.35456698 0.00014909593 -1.281103 0.50420631 -0.2558317 0.0001479347 -1.2651262 0.51429788 -0.28893557 0.00014655593 -1.2494004 0.52135123 -0.27882309 0.00014412602"
    s = s + " -1.2339522 0.52756595 -0.23217506 0.00014437838 -1.2187168 0.53480958 -0.26406268 0.00014432408 -1.2037702 0.54338564 -0.29729024 0.00014262955 -1.1890155 0.54817266 -0.24900712 0.00014111421 -1.1744677 0.55263933 -0.22129035 0.00014067648 -1.1601444 0.55919565 -0.23623151 0.00013973685 -1.1460177 0.56517698 -0.24565447 0.00013926384 -1.1320096 0.56603215 -0.17524226 0.0001396978 -1.1182292 0.57011095 -0.19439876 0.00013916343 -1.1045866 0.57209736 -0.16074907 0.00013818167"
    s = s + " -1.0911074 0.5723485 -0.10524258 0.00013722018 -1.0777556 0.57229676 -0.032550732 0.00013619288 -1.0645684 0.57302396 0.014379749 0.0001355341 -1.0515244 0.5736259 0.08463918 0.00013526527 -1.0386317 0.57725998 0.07359064 0.00013519196 -1.0258492 0.5804434 0.051060038 0.00013379316 -1.01317 0.58385933 0.0061245025 0.0001342836 -1.000627 0.58959535 -0.064975446 0.00013403253 -0.9881634 0.58962904 -0.03896917 0.00013388645 -0.97580892 0.59228543 -0.092028608 0.00013256283"
    s = s + " -0.96353988 0.59023118 -0.025245537 0.00013350108 -0.95135437 0.59235081 -0.066927698 0.00013166673 -0.93927127 0.59495523 -0.11772564 0.00013109874 -0.92725721 0.59465251 -0.098842151 0.00013075847 -0.91538294 0.59862948 -0.1337387 0.00012991997 -0.90351591 0.59736071 -0.11575297 0.00013004651 -0.8917174 0.59827558 -0.11376391 0.00012981779 -0.87999358 0.59854644 -0.11262976 0.0001293793 -0.86836393 0.60125923 -0.1570054 0.00012809482 -0.8567663 0.60235243 -0.15341154 0.0001272749"
    s = s + " -0.84521821 0.60724747 -0.28142705 0.00012854899 -0.83368446 0.60414764 -0.22759417 0.00012886527 -0.82217754 0.5988247 -0.1036938 0.0001272911 -0.81077477 0.60266754 -0.1923692 0.00012744791 -0.79938013 0.60203622 -0.1545566 0.00012851757 -0.7879978 0.60310963 -0.21236507 0.0001284728 -0.77666556 0.60512141 -0.24195949 0.00012867783 -0.76531152 0.6016104 -0.18435951 0.00012764627 -0.75400509 0.60005644 -0.15758711 0.00012719162 -0.7427255 0.60263001 -0.19073741 0.00012737733"
    s = s + " -0.7314095 0.60169755 -0.1680994 0.00012901165 -0.72010821 0.60073899 -0.17118517 0.00012989901 -0.70881438 0.60281341 -0.19734629 0.00013096756 -0.69752254 0.605741 -0.2390057 0.00013200027 -0.68621242 0.60709003 -0.25007855 0.00013205742 -0.67486899 0.60595186 -0.21780355 0.00013308173 -0.6635531 0.60879991 -0.23907614 0.00013334734 -0.65217906 0.6093449 -0.22402739 0.00013313113 -0.6407847 0.61045036 -0.22525697 0.00013423481 -0.62935668 0.61165455 -0.18555733 0.00013561164"
    s = s + " -0.61784992 0.60906224 -0.1021716 0.00013524395 -0.60634066 0.61133645 -0.093563312 0.00013574028 -0.59479908 0.61243094 -0.018009253 0.00013677974 -0.58317131 0.61383424 0.033976678 0.00013851627 -0.57147764 0.61383949 0.12970947 0.0001391928 -0.55974664 0.61815202 0.13567448 0.00013865735 -0.54796415 0.62425007 0.12681084 0.00014027742 -0.53605781 0.62788652 0.1392266 0.00014160362 -0.52407823 0.63003047 0.2001274 0.00014263868 -0.51203077 0.63456809 0.22849852 0.00014476471"
    s = s + " -0.49993482 0.6410294 0.23651226 0.00014745515 -0.48774646 0.64854569 0.1918391 0.00014882984 -0.47546258 0.65391229 0.20689462 0.0001506309 -0.46312562 0.6619045 0.15084854 0.00015052565 -0.45068236 0.67032467 0.10052172 0.00015261383 -0.43816571 0.67906278 0.018043158 0.00015193656 -0.42553012 0.68596166 -0.034373075 0.00015324255 -0.41278915 0.68751627 0.0018499262 0.00015211374 -0.39996901 0.69262508 -0.044106098 0.00015262241 -0.38705587 0.69470103 -0.03722354 0.00015233648"
    s = s + " -0.37407697 0.69915156 -0.068104682 0.00015310849 -0.361036 0.70418582 -0.098476385 0.0001541773 -0.34792319 0.70730664 -0.10085193 0.00015510072 -0.33471267 0.71104064 -0.12671226 0.00015539396 -0.32142107 0.71478513 -0.15318544 0.00015678198 -0.30803148 0.71372891 -0.10938638 0.0001588677 -0.29463058 0.72056282 -0.22811198 0.00015869168 -0.28109052 0.72106303 -0.20822006 0.00015986958 -0.26754399 0.73003235 -0.37500115 0.00016005206 -0.25384762 0.7308834 -0.36414154 0.00015982446"
    s = s + " -0.24009915 0.73329574 -0.39708747 0.00016064215 -0.22627489 0.735505 -0.38861738 0.00016028259 -0.21236427 0.73562685 -0.37745695 0.00015906987 -0.19835027 0.73617467 -0.37412904 0.00015881342 -0.18428951 0.73644506 -0.34303983 0.00016010471 -0.17011954 0.73618375 -0.29890353 0.00016091489 -0.1558682 0.73373246 -0.2270809 0.00016122387 -0.14152198 0.73271165 -0.21753843 0.00015985951 -0.12710086 0.73048568 -0.16997032 0.00015998493 -0.11258798 0.72754793 -0.10077334 0.00015998672"
    s = s + " -0.09797607 0.72884778 -0.1089758 0.00016140512 -0.083287262 0.73024638 -0.10172413 0.00016110431 -0.06849948 0.73431662 -0.1856636 0.00016282783 -0.053596308 0.73398093 -0.15607347 0.00016572782 -0.03859197 0.73389218 -0.17541939 0.00016622391 -0.023470382 0.73281912 -0.18774382 0.00016697962 -0.0082414051 0.73243552 -0.16681816 0.00016735938 0.0070938188 0.73311643 -0.16926117 0.00017001641 0.022558531 0.73323536 -0.16912639 0.0001713441 0.03812404 0.73423643 -0.21631637 0.00017166919"
    s = s + " 0.053822876 0.73695639 -0.24374285 0.00017135216 0.069723974 0.73497901 -0.21283984 0.0001717885 0.085748648 0.73353054 -0.22887618 0.00017378309 0.10194776 0.72751724 -0.14073615 0.00017367948 0.11822374 0.72919921 -0.19181418 0.00017409813 0.13466118 0.72841873 -0.20592264 0.00017404024 0.15123202 0.72748214 -0.142825 0.00017445653 0.16799709 0.72206466 -0.015965775 0.00017698924 0.1849277 0.71874017 0.066004976 0.00017778151 0.20202274 0.71934368 0.025624359 0.00017955598"
    s = s + " 0.21927304 0.72039275 0.02558038 0.00018184571 0.23678102 0.71748717 0.094060252 0.00018364653 0.25451636 0.70885897 0.25088485 0.00018473165 0.27238855 0.70503684 0.37460085 0.00018585039 0.2904553 0.70469131 0.43622979 0.00018669006 0.30876289 0.69991385 0.57078447 0.0001873182 0.32730986 0.69817689 0.65322255 0.00018881434 0.34608201 0.6995444 0.65207222 0.00018932827 0.3650916 0.7011835 0.66744563 0.00019036477 0.3843845 0.70479523 0.63848692 0.00019104889"
    s = s + " 0.40399054 0.70127591 0.77381319 0.00019254653 0.42381859 0.70578585 0.77661271 0.00019357949 0.44400981 0.70845188 0.76564843 0.000192708 0.46452123 0.71504692 0.66984153 0.00019399621 0.48536196 0.71727201 0.7293499 0.00019557474 0.50650098 0.73110911 0.54567534 0.00019837528 0.52811782 0.72881888 0.7389034 0.00019966728 0.55006427 0.73523577 0.74836455 0.00019991704 0.57244866 0.74134438 0.80091013 0.00019902737 0.59531037 0.74367625 0.91978665 0.00020239438"
    s = s + " 0.61869583 0.74658014 0.99643135 0.00020585053 0.6424973 0.76305579 0.87771089 0.00020526129 0.66691707 0.76996444 0.97362052 0.00020866944 0.69183128 0.78557766 0.88754062 0.00020955134 0.71744906 0.80040433 0.80308001 0.00021295825 0.74377276 0.8121428 0.83723176 0.00021328053 0.77080898 0.82540821 0.85895798 0.00021879241 0.79865774 0.83593059 0.91965289 0.00022425873 0.8274514 0.84399837 1.0515597 0.00022793382 0.8570601 0.8606473 1.1167888 0.00023196873"
    s = s + " 0.88773648 0.8764175 1.1796358 0.000239097 0.91952791 0.89954267 1.1230715 0.00023965676 0.95259765 0.91572736 1.3446001 0.00024244577 0.98685842 0.94668499 1.3083248 0.00024366251 1.0226723 0.97271007 1.525428 0.00024879761 1.0602764 1.0038143 1.5791882 0.00025394977 1.0998111 1.0352814 1.8038552 0.00025746326 1.1415718 1.0682334 2.0945465 0.00025962231 1.1857427 1.1068815 2.4142752 0.0002629678 1.2329803 1.1470414 2.8497297 0.0002668687"
    s = s + " 1.2836101 1.2111123 2.9446612 0.000274748 1.3383168 1.2755673 3.3808455 0.00028272951 1.3981251 1.3492646 3.800062 0.00029185651 1.4640642 1.4544896 4.1103714 0.00031385459 1.5383455 1.5713643 4.61051 0.00032810887 1.6233569 1.7314438 5.1765144 0.00035016457 1.7241804 1.926988 6.350803 0.00038437873 1.8485834 2.2458904 7.2317207 0.00041561758 2.0150248 2.7264767 8.8446031 0.00048601732 2.0567136 2.8527315 9.6184847 0.00051796899"
    s = s + " 2.1027347 3.0008151 10.382866 0.00053898121 2.1540126 3.1822666 11.07189 0.0005577211 2.2124108 3.345449 12.865521 0.00058784437 2.279742 3.6015037 14.01974 0.00063354539 2.3603355 3.9707581 14.523069 0.00071569175 2.4616852 4.4258179 15.562243 0.00077596696 2.6009217 4.9197115 22.640137 0.00090787028 2.8233497 6.3045355 26.417722 0.0011716504 3.0328032 7.5631954 35.087491 0.0016240091 3.2991405 9.4748927 53.382413 0.0023643422"
    s = s + " 3.4781086 10.960181 65.777105 0.0031382626"
    v = strtoreal(tokens(s))
    return(rowshape(v, 221))
}

real matrix bu_urc_c()
{
    string scalar s
    real rowvector v
    s = ""
    s = s + " -4.6498737 -19.585128 -134.04859 0.0028987599 -4.4931648 -16.807926 -122.0471 0.0022083 -4.2675648 -14.425831 -87.644297 0.0014140247 -4.0912176 -12.441367 -68.492333 0.0010882695 -3.9058347 -10.513102 -51.918428 0.0007795883 -3.7927154 -9.4090272 -44.208442 0.00066318864 -3.7100105 -8.6780936 -37.830866 0.00059497541 -3.643575 -8.1822049 -32.355767 0.00055007457 -3.589081 -7.6729277 -30.421975 0.00050967313 -3.5421556 -7.3119578 -27.319567 0.00048484389"
    s = s + " -3.5007351 -6.9999449 -25.038104 0.00045285603 -3.4637847 -6.7024239 -23.833155 0.00043212199 -3.4301855 -6.4601835 -22.150622 0.0004062553 -3.2980044 -5.5041761 -17.079587 0.00035316546 -3.2003475 -4.8184935 -14.518699 0.00031144263 -3.1220215 -4.3156408 -12.363387 0.00028433742 -3.0560484 -3.9360126 -10.355988 0.00027365317 -2.998901 -3.6004495 -9.2929232 0.00025607319 -2.9484715 -3.3101354 -8.2865912 0.00024419727 -2.9028807 -3.0689608 -7.3753301 0.00023798936"
    s = s + " -2.8613794 -2.858389 -6.5356937 0.0002256829 -2.8231707 -2.6704867 -5.8684031 0.00022093751 -2.787681 -2.5009584 -5.2732527 0.00021380944 -2.7545889 -2.3414925 -4.8579683 0.00020908348 -2.723494 -2.1950703 -4.5079621 0.00020412734 -2.6940314 -2.0720578 -4.0170328 0.00019962789 -2.6661673 -1.9520849 -3.6714342 0.00019401044 -2.6395787 -1.8455989 -3.2400536 0.00019334773 -2.6142084 -1.7412463 -2.9756301 0.00018854058 -2.589969 -1.6382011 -2.818905 0.00018342614"
    s = s + " -2.5666852 -1.5407058 -2.6824738 0.00017867718 -2.5442992 -1.4455909 -2.6141252 0.00017529619 -2.5226529 -1.3636472 -2.4331178 0.00017198577 -2.5017734 -1.2860456 -2.2376568 0.00016710155 -2.4815082 -1.214656 -2.002867 0.00016209084 -2.4618127 -1.1438367 -1.9410583 0.0001581832 -2.4427398 -1.0795815 -1.7379897 0.00015707067 -2.4242373 -1.0129871 -1.6157265 0.00015540008 -2.4061235 -0.95863004 -1.3584182 0.00015496957 -2.3884705 -0.90317855 -1.1645286 0.00015380726"
    s = s + " -2.3712834 -0.8489709 -1.0361953 0.00015197444 -2.3544588 -0.79871409 -0.89103868 0.00015155235 -2.3380393 -0.7470885 -0.82182554 0.00015056603 -2.3219515 -0.70155967 -0.63796928 0.00014928147 -2.3061761 -0.65942293 -0.43314474 0.00014830706 -2.290754 -0.6128591 -0.36048529 0.0001472114 -2.2756297 -0.56779943 -0.29121491 0.00014719167 -2.260788 -0.52409236 -0.25606839 0.00014580297 -2.2462575 -0.47609723 -0.30994831 0.00014528649 -2.2318566 -0.43929292 -0.22440805 0.00014505919"
    s = s + " -2.217773 -0.39701536 -0.24856318 0.00014188639 -2.2038352 -0.36444851 -0.11354554 0.0001417164 -2.1901914 -0.32532352 -0.093216784 0.00014218242 -2.1767391 -0.28747114 -0.10310017 0.00014155611 -2.1634883 -0.25016662 -0.10675131 0.00014050226 -2.1503874 -0.21601205 -0.10476651 0.00014015033 -2.1374432 -0.1858336 -0.051211317 0.00014011318 -2.124642 -0.15683431 -0.029204874 0.00013883378 -2.1120088 -0.13213346 0.12852807 0.00013857794 -2.0995474 -0.099815891 0.099058341 0.00013742797"
    s = s + " -2.0872295 -0.070378462 0.10800415 0.00013793884 -2.0750609 -0.042044889 0.14101216 0.00013621927 -2.0630352 -0.015141684 0.18865304 0.00013639356 -2.051136 0.015952055 0.10012626 0.00013490015 -2.0393918 0.044522529 0.086565146 0.00013472776 -2.0277077 0.067059234 0.16819054 0.00013407648 -2.016149 0.090904806 0.19550829 0.00013409339 -2.004692 0.11665323 0.15704451 0.00013291655 -1.9933276 0.13968718 0.17247884 0.00013151197 -1.9820619 0.16173157 0.19898819 0.00013162402"
    s = s + " -1.970886 0.18237481 0.25236052 0.00013061907 -1.9598292 0.20391525 0.28727209 0.00013018764 -1.9488223 0.22372134 0.32812856 0.00012990573 -1.9379266 0.24774843 0.26125313 0.0001296202 -1.9270853 0.26745749 0.2697937 0.00012787068 -1.9163151 0.28673153 0.28767581 0.0001281965 -1.9056274 0.30480271 0.31440368 0.00012750112 -1.8950092 0.3248774 0.2928928 0.00012633421 -1.8844373 0.34183301 0.33094959 0.0001261714 -1.8739396 0.36093334 0.29415769 0.00012542124"
    s = s + " -1.8635243 0.38142067 0.22614552 0.00012490566 -1.8531302 0.39716105 0.24303066 0.0001248705 -1.8427987 0.4096043 0.36111823 0.00012450876 -1.832549 0.42827858 0.35044668 0.00012429566 -1.822312 0.44312533 0.38373089 0.00012339286 -1.8121476 0.45825395 0.41736017 0.00012354584 -1.8020189 0.47456176 0.39780568 0.00012299378 -1.7919441 0.49156607 0.37160352 0.00012115398 -1.7818927 0.50669755 0.35931258 0.00012090362 -1.7718547 0.52020078 0.3685279 0.00011990979"
    s = s + " -1.7618784 0.53552131 0.37399927 0.00012096096 -1.7519035 0.5466972 0.42995618 0.00012096099 -1.7419868 0.56180886 0.40902997 0.00012127621 -1.7321082 0.57467469 0.42868053 0.0001203501 -1.7222375 0.58708826 0.45175084 0.00012043651 -1.7123798 0.59917697 0.48860303 0.00012051206 -1.7025509 0.61170671 0.49474275 0.00012071179 -1.6927408 0.62506026 0.46000167 0.00012050594 -1.6829693 0.63659023 0.49564593 0.00012111163 -1.6731939 0.64805654 0.50804098 0.00012038583"
    s = s + " -1.6634091 0.65672036 0.55607608 0.00012102541 -1.6536497 0.66769315 0.55911498 0.00012149389 -1.6439062 0.67742799 0.59076277 0.00012261731 -1.6341886 0.68994994 0.56825647 0.00012213119 -1.6244687 0.70100834 0.57240705 0.00012293942 -1.6147364 0.71044565 0.60084676 0.00012159089 -1.6050132 0.72047181 0.61499829 0.00012113944 -1.5952755 0.72923289 0.6508903 0.00012120266 -1.5855407 0.7394689 0.6451626 0.00012082145 -1.575834 0.7491741 0.64206303 0.00012086709"
    s = s + " -1.5661226 0.76123129 0.60141833 0.00012178366 -1.5563725 0.76883728 0.64611202 0.00012207516 -1.5466262 0.77749522 0.67164232 0.00012318791 -1.5368887 0.79044802 0.59971309 0.0001234695 -1.5271193 0.80044531 0.60613339 0.00012451886 -1.5173571 0.80941987 0.6172132 0.00012384741 -1.5075829 0.82011412 0.59323485 0.00012382238 -1.4977672 0.83044274 0.58712998 0.0001238026 -1.4879122 0.83904973 0.59087687 0.00012307983 -1.4780499 0.84732674 0.61608062 0.0001226664"
    s = s + " -1.4681619 0.8567715 0.60979842 0.00012252223 -1.4582463 0.86435803 0.64988385 0.00012330911 -1.4482883 0.87451774 0.61543666 0.00012347216 -1.4382813 0.88263113 0.62973992 0.00012380557 -1.4282536 0.88956398 0.67468172 0.00012417842 -1.4182008 0.89929049 0.67428793 0.00012422941 -1.4080885 0.90829942 0.67159819 0.00012506386 -1.3979342 0.91703848 0.66877596 0.00012625226 -1.3877694 0.92859017 0.61995067 0.00012699355 -1.377523 0.93604289 0.63846649 0.00012666064"
    s = s + " -1.3672057 0.94426847 0.6251151 0.00012737116 -1.3568339 0.95188127 0.63766879 0.00012721756 -1.3464079 0.95959007 0.66127287 0.00012944453 -1.3359058 0.96366545 0.74578117 0.000130002 -1.3253685 0.97110447 0.79643193 0.00013007992 -1.3147624 0.97855405 0.83213055 0.00013042507 -1.3041106 0.98835692 0.81911505 0.00013139037 -1.2933783 0.99697287 0.86808312 0.00013181101 -1.2825497 1.0047337 0.89757564 0.00013204824 -1.2716606 1.0146399 0.90814494 0.00013257959"
    s = s + " -1.2606975 1.0258937 0.87659985 0.00013332493 -1.249625 1.0349109 0.88896456 0.00013332758 -1.2384725 1.0438386 0.91800985 0.00013398711 -1.2271853 1.0534207 0.9059538 0.0001346633 -1.2158071 1.0597995 1.0029103 0.00013481324 -1.2043342 1.0694094 1.0105287 0.00013585221 -1.1927374 1.0817023 0.96515325 0.00013634858 -1.1810471 1.0916938 1.0085506 0.00013694656 -1.1692236 1.1026291 1.026851 0.00013788806 -1.1572565 1.1113878 1.063002 0.00013883535"
    s = s + " -1.1451871 1.1272707 0.97342183 0.00013931866 -1.1329554 1.1390215 0.97571997 0.00014041549 -1.1205568 1.1488008 1.0272798 0.0001409265 -1.1080251 1.1621514 0.9981148 0.00014220521 -1.0953689 1.1751472 0.99909208 0.00014229817 -1.0825027 1.184276 1.1029791 0.00014424766 -1.0694471 1.1955497 1.1515205 0.00014635427 -1.0562396 1.2073469 1.1921759 0.00014761855 -1.0428562 1.223239 1.1346513 0.00014852001 -1.029262 1.2348075 1.1945083 0.00014902807"
    s = s + " -1.0154635 1.2433879 1.3252913 0.00014947863 -1.0014375 1.2567831 1.3560022 0.00015208154 -0.98722361 1.2729485 1.3623659 0.00015296326 -0.97276525 1.2849843 1.4498376 0.000153746 -0.95804968 1.2990845 1.4649926 0.00015448352 -0.94307789 1.3116712 1.5199257 0.00015402427 -0.92788147 1.3271247 1.5335271 0.00015443462 -0.91240062 1.3458079 1.4685748 0.00015632675 -0.89662363 1.3603465 1.5140667 0.0001568523 -0.88051439 1.3707204 1.6170701 0.00015674102"
    s = s + " -0.86415213 1.390553 1.5259264 0.00015760527 -0.84741271 1.4046344 1.552914 0.00015989949 -0.83034617 1.4173885 1.620925 0.00016350912 -0.81294478 1.4362241 1.555192 0.00016586488 -0.79514864 1.4511181 1.5562824 0.00016590867 -0.77696661 1.4677019 1.5249573 0.00016638401 -0.75843335 1.4815932 1.5680324 0.00016662967 -0.73948936 1.5027783 1.401677 0.00017062759 -0.72001765 1.5155065 1.4202473 0.00017421195 -0.7000796 1.5308187 1.3741596 0.00017593826"
    s = s + " -0.67965634 1.5432939 1.4005642 0.0001794182 -0.65874834 1.5628266 1.2723723 0.00018215045 -0.63728288 1.5767863 1.2949684 0.00018458866 -0.6152009 1.5943728 1.2109636 0.00018836483 -0.59249185 1.6124836 1.1000707 0.00019057883 -0.56903837 1.6211059 1.1553 0.00019433841 -0.54503602 1.6400816 1.1198099 0.00019489117 -0.52014209 1.6479358 1.2904679 0.00019787026 -0.49448261 1.6663249 1.23304 0.00020123336 -0.46782751 1.6726921 1.4163846 0.00020200546"
    s = s + " -0.44022652 1.6912618 1.2920816 0.00020616949 -0.41150914 1.7030679 1.3956081 0.00020791146 -0.3816396 1.7218323 1.2886276 0.00021143949 -0.35052328 1.7449335 1.2444879 0.00021608096 -0.31784963 1.7583988 1.3309349 0.00022137616 -0.28358669 1.7819671 1.1939449 0.0002282461 -0.24752936 1.8043432 1.1492554 0.0002334428 -0.20921434 1.8128613 1.4681372 0.00023912457 -0.16854843 1.8291524 1.6811082 0.00024296201 -0.1250677 1.8484229 1.8448104 0.00024956133"
    s = s + " -0.078452312 1.8935948 1.648603 0.00025539564 -0.02779895 1.9267952 1.7041255 0.00025829514 0.027706392 1.9619369 1.8949738 0.00026897317 0.089286662 1.9957209 2.2039115 0.00028266973 0.15856116 2.0391692 2.5297069 0.00030069415 0.23824409 2.0909362 2.9792799 0.00032333274 0.33270796 2.1330179 4.311973 0.00035243873 0.44958524 2.2800521 4.2114918 0.0003918326 0.60714202 2.457835 5.4652585 0.00044240428 0.64662561 2.5244955 5.5903544 0.00046150771"
    s = s + " 0.69039936 2.5833949 5.9261945 0.00048237641 0.73897923 2.6541195 6.3608976 0.00050414902 0.79395621 2.7338103 7.1352379 0.00054670677 0.85790385 2.8512874 8.0839936 0.00059870411 0.93404481 3.0496355 8.2089804 0.00066194575 1.0303788 3.2107748 10.398269 0.00075922721 1.1623571 3.4537569 14.242427 0.00090555619 1.3751885 4.0430952 19.400154 0.0011609585 1.5748041 4.717652 24.795177 0.001549166 1.8295984 5.9233078 29.935654 0.0023156824"
    s = s + " 2.0018937 6.5929082 40.856258 0.0030589721"
    v = strtoreal(tokens(s))
    return(rowshape(v, 221))
}

real matrix bu_urc_ct()
{
    string scalar s
    real rowvector v
    s = ""
    s = s + " -5.1292249 -26.719405 -71.505058 -1813.2204 0.0033885902 -4.9772843 -23.023496 -106.2591 -824.40218 0.0026636323 -4.7675056 -18.937358 -106.17991 -284.37677 0.0017715683 -4.5953135 -16.764209 -68.301228 -462.16138 0.0012267776 -4.4175149 -14.124948 -60.038464 -323.3844 0.00093777691 -4.3074125 -12.945902 -44.683263 -336.47743 0.00079468331 -4.2275728 -12.030693 -36.566098 -352.38619 0.0006911358 -4.1638843 -11.350053 -32.774943 -292.7785 0.00063012787 -4.1111804 -10.738118 -32.793566 -222.42918 0.00058445069 -4.0655516 -10.355485 -24.941082 -269.16719 0.00055462829"
    s = s + " -4.025716 -9.9051615 -24.342994 -238.23165 0.00053346611 -3.9903382 -9.4980973 -24.469611 -202.11084 0.00051061829 -3.9579703 -9.1969574 -22.702701 -188.39198 0.00048941112 -3.8304297 -7.9968631 -15.371282 -186.22806 0.00041578111 -3.7359746 -7.1683122 -11.342941 -164.67362 0.00037278025 -3.6604348 -6.4961092 -9.8084411 -138.65435 0.00033483802 -3.5971452 -5.958473 -7.6698007 -139.80717 0.00031748485 -3.5420886 -5.5368953 -4.9209822 -151.27142 0.00029998883 -3.4933873 -5.161807 -3.8734324 -141.61612 0.00028230115 -3.4498312 -4.7945374 -4.5103958 -118.19984 0.00026593309"
    s = s + " -3.4098271 -4.5119686 -3.6630374 -109.96942 0.00026006414 -3.3731039 -4.253054 -2.6810539 -111.47716 0.00025015961 -3.3389269 -4.0161454 -2.2793812 -105.99232 0.00024376895 -3.3071958 -3.7837582 -2.6840288 -88.568817 0.00023631403 -3.2772698 -3.5989629 -1.4096929 -97.886557 0.00023105111 -3.2490638 -3.4004849 -1.8647137 -82.041248 0.00022374466 -3.2222496 -3.2298164 -1.6497471 -76.770146 0.00021599403 -3.1966701 -3.0914518 -0.46648607 -84.83216 0.00021510158 -3.1723541 -2.9442737 -0.25122362 -79.841118 0.00021196397 -3.1490499 -2.7984615 -0.60841107 -67.248271 0.00020392752"
    s = s + " -3.1266008 -2.6801993 0.18064468 -70.5668 0.00019867722 -3.1050614 -2.5556146 0.3048303 -66.331356 0.00019657521 -3.0842631 -2.4325536 0.055237751 -57.441312 0.00019363302 -3.064124 -2.3516058 1.9369931 -78.41441 0.00018938648 -3.0447284 -2.2387749 1.9473749 -76.524563 0.00018911144 -3.0258531 -2.138032 2.0895666 -75.536284 0.00018775206 -3.0075743 -2.0346668 1.9087771 -69.841588 0.00018362816 -2.9897721 -1.9406836 1.6726132 -61.191433 0.00018188085 -2.9724186 -1.8630055 2.1982439 -62.991422 0.00017953184 -2.9556152 -1.7764191 2.3943049 -63.323257 0.00017739996"
    s = s + " -2.939127 -1.7019814 2.9011393 -67.401446 0.00017631621 -2.9230915 -1.6194464 2.9100092 -65.734967 0.00017383308 -2.9073542 -1.5544466 3.3714972 -68.447922 0.00017132397 -2.8920421 -1.4746117 3.287292 -65.347757 0.00017065386 -2.8770072 -1.3999656 3.1762313 -62.357562 0.00016854506 -2.8622767 -1.3248669 2.9248375 -57.117555 0.00016775877 -2.8478144 -1.2576021 3.0275682 -57.490293 0.000168107 -2.8336368 -1.1832725 2.5774957 -50.417268 0.00016717041 -2.8196693 -1.1351672 3.2842425 -56.866936 0.00016507566 -2.8059229 -1.0897831 4.0987862 -65.845043 0.00016409938"
    s = s + " -2.7924244 -1.0357843 4.3139195 -66.451953 0.00016122474 -2.7791594 -0.98116276 4.4046139 -65.621184 0.00016021626 -2.7660918 -0.9356533 4.9513456 -71.803048 0.00016028087 -2.753295 -0.87603023 4.7595728 -68.431777 0.00016026079 -2.740577 -0.83901838 5.4578623 -74.961638 0.00015959372 -2.7281403 -0.7784162 4.9174947 -65.332097 0.00015821915 -2.7158486 -0.72739169 4.9094846 -64.184597 0.00015675119 -2.7037032 -0.67268668 4.4944629 -56.574353 0.00015596401 -2.691673 -0.62973528 4.5915487 -55.634219 0.00015596307 -2.6798653 -0.5769469 4.2675244 -50.038814 0.00015574682"
    s = s + " -2.6681478 -0.53657585 4.4389738 -50.652347 0.00015428007 -2.6566314 -0.48471837 4.0575016 -44.261354 0.00015527884 -2.6452172 -0.44006839 4.0839919 -44.101683 0.00015518621 -2.6339288 -0.3908084 3.592295 -35.487137 0.0001530364 -2.622692 -0.356808 3.9609952 -39.628037 0.00015324745 -2.6116268 -0.31585896 3.8918079 -37.337359 0.00015411009 -2.6007008 -0.27508044 3.8825003 -37.238795 0.00015260244 -2.5898604 -0.23595815 3.8374761 -35.703014 0.00015206038 -2.5791024 -0.19275104 3.6180677 -32.854471 0.00015233346 -2.568478 -0.14422428 2.9497493 -23.265165 0.00015187371"
    s = s + " -2.5578907 -0.11708115 3.4865837 -30.227654 0.00015146681 -2.5474479 -0.078928335 3.3787342 -28.511927 0.00015084094 -2.537051 -0.046002003 3.4911293 -29.808341 0.00015135005 -2.5267346 -0.0088433368 3.2582071 -25.573831 0.00015146718 -2.5165101 0.030239666 2.940012 -21.369329 0.00015071137 -2.5063486 0.057189111 3.1815506 -23.456797 0.00015069188 -2.4963173 0.096684467 2.8368008 -18.8104 0.00014896826 -2.4863552 0.13442678 2.5591894 -15.152288 0.00014803579 -2.4764134 0.16707005 2.3911364 -12.213498 0.00014642068 -2.4665145 0.19830071 2.2971835 -9.9591831 0.00014631912"
    s = s + " -2.4567076 0.22601828 2.4265859 -11.559708 0.00014551435 -2.4469298 0.25058604 2.6670623 -14.42383 0.00014500881 -2.4372232 0.27801061 2.6743891 -13.439708 0.0001446792 -2.4276224 0.31395462 2.2621507 -7.5122092 0.00014434048 -2.418023 0.3384695 2.3723621 -8.151206 0.00014468125 -2.408501 0.37196042 2.1008909 -5.0165956 0.00014364886 -2.3990018 0.40127084 1.850321 0.094670959 0.00014471542 -2.3895519 0.42357106 2.0564043 -2.0926551 0.00014384185 -2.3801178 0.44483141 2.3172042 -5.7502842 0.00014349328 -2.3707386 0.46799263 2.4510974 -7.8690664 0.00014289131"
    s = s + " -2.3613945 0.48453194 2.8496225 -12.430669 0.00014246123 -2.3521315 0.51224819 2.7172324 -10.805897 0.00014311951 -2.3428615 0.53499021 2.7393295 -10.47717 0.00014373853 -2.3336594 0.56658689 2.3561888 -5.6697405 0.0001437255 -2.324455 0.58537293 2.573145 -8.3767262 0.00014275271 -2.3152939 0.61050006 2.3544778 -4.5072384 0.00014221504 -2.3061545 0.63321402 2.2490796 -2.3168224 0.00014150262 -2.2970767 0.6571268 2.1628346 -1.1015245 0.00014192615 -2.2879866 0.67872982 2.0570538 1.1234809 0.00014112228 -2.2789051 0.68916911 2.6927433 -7.4046893 0.00014024701"
    s = s + " -2.2698488 0.70828441 2.7444158 -7.4737131 0.00013996383 -2.2608368 0.73335832 2.4663581 -3.2373265 0.00014066022 -2.2518533 0.75221949 2.5753942 -4.6643976 0.00014096756 -2.2428768 0.77080224 2.7153251 -6.6507102 0.00013965135 -2.233945 0.79382399 2.6031705 -5.2426895 0.00013841971 -2.2250064 0.81629951 2.4828676 -3.8413947 0.00013786648 -2.2160811 0.84061753 2.2139888 -0.016662817 0.00013701353 -2.2071578 0.85684905 2.4074056 -2.462436 0.00013804943 -2.19826 0.87649237 2.4263314 -3.0569545 0.00013797874 -2.1893693 0.89717147 2.3049354 -0.91761864 0.00013818453"
    s = s + " -2.1804723 0.9140739 2.3926728 -2.1744109 0.00013840677 -2.1715633 0.93349657 2.3061015 -0.90584152 0.00013761597 -2.1626276 0.93971963 2.8345674 -7.1659328 0.00013832364 -2.1537543 0.95788791 2.9207276 -8.9025672 0.00013807326 -2.1448725 0.97685127 2.8226055 -7.3310995 0.00013747915 -2.1360234 1.0018044 2.5081261 -3.7834633 0.00013608001 -2.127141 1.0221381 2.3591607 -1.755275 0.00013647218 -2.1182572 1.0376907 2.4550352 -2.8045144 0.00013606637 -2.1093539 1.0545503 2.4832597 -3.6485319 0.00013663996 -2.1004392 1.0707521 2.516962 -4.3821238 0.00013792304"
    s = s + " -2.0915177 1.076621 3.1197524 -12.823056 0.00013844332 -2.0825577 1.0893451 3.1880812 -13.158546 0.00013863815 -2.0736342 1.1094116 2.96821 -10.46919 0.00013787602 -2.0646655 1.1188882 3.388107 -16.443775 0.00013929772 -2.0556978 1.1354394 3.3064686 -15.043946 0.00013896461 -2.0467186 1.154045 3.1419242 -12.67585 0.00014019431 -2.0377119 1.1701541 3.1345858 -12.88273 0.0001403696 -2.0286865 1.1840489 3.2405907 -14.277327 0.00014100853 -2.0196066 1.1908254 3.6997872 -20.796341 0.0001399728 -2.0105035 1.1986852 4.0948873 -26.41497 0.0001400136"
    s = s + " -2.0014101 1.2174824 3.838716 -22.856574 0.000139146 -1.9922608 1.225849 4.1415715 -26.562092 0.00013826548 -1.9831055 1.242126 4.1281558 -26.661964 0.00013867907 -1.9739381 1.2638568 3.7981407 -22.613934 0.00013827443 -1.9646817 1.2662124 4.4468385 -31.496535 0.00013817797 -1.9554013 1.2818893 4.2857828 -28.94869 0.00013691489 -1.9460905 1.2949651 4.3324966 -29.752916 0.00013695602 -1.9367325 1.30594 4.5148127 -32.156138 0.0001365365 -1.9273449 1.3196473 4.4970527 -32.103802 0.00013685557 -1.917942 1.3390194 4.2389864 -28.474253 0.0001368387"
    s = s + " -1.9084974 1.3616852 3.8076995 -23.024484 0.00013672194 -1.8989633 1.3792449 3.5856095 -19.966922 0.00013753257 -1.8893909 1.4027174 3.0218952 -12.727231 0.00013828068 -1.8797154 1.4114457 3.2282461 -14.933104 0.00013922397 -1.8700179 1.4268665 3.1472097 -14.232556 0.00014006429 -1.8602368 1.4356002 3.4593436 -18.790799 0.00014016004 -1.8504258 1.4500848 3.3863764 -17.434797 0.00014059273 -1.8405255 1.4662367 3.2540039 -16.131579 0.0001412837 -1.8305438 1.4807586 3.1937663 -15.461995 0.00014214132 -1.8204991 1.4948178 3.2497226 -16.927232 0.00014075805"
    s = s + " -1.810351 1.5097792 3.1988594 -16.425651 0.00014139416 -1.8001244 1.5250088 3.065401 -14.728335 0.00014027316 -1.789788 1.5308619 3.408534 -18.667621 0.00014037122 -1.7793754 1.5397714 3.6001242 -20.58658 0.00014081775 -1.7688669 1.5515074 3.6250524 -20.123236 0.00014178541 -1.7582836 1.5657976 3.710857 -21.530377 0.00014184305 -1.7476215 1.5888913 3.3709576 -18.128033 0.00014275169 -1.7368102 1.6075322 3.0628266 -13.698175 0.00014441364 -1.7258802 1.6217158 2.9465403 -10.831516 0.00014414746 -1.7147789 1.6263007 3.3347902 -14.567624 0.00014487648"
    s = s + " -1.7036055 1.6385091 3.5964522 -19.478659 0.0001458091 -1.6923035 1.6575011 3.387545 -16.471074 0.00014675254 -1.6808178 1.6735087 3.3470112 -15.979085 0.00014779663 -1.6692208 1.6976318 2.9191207 -11.105685 0.00014845919 -1.6574499 1.712672 3.0190391 -12.544351 0.00014911957 -1.6455203 1.7321196 2.7843557 -8.8951804 0.00015133137 -1.6334202 1.7505771 2.7140815 -8.4134683 0.0001511422 -1.6211175 1.7647263 2.830155 -9.3961723 0.00015302209 -1.6086311 1.7808217 2.8613978 -9.3538199 0.00015394567 -1.5959047 1.7966812 2.9838201 -11.103841 0.00015518715"
    s = s + " -1.5830072 1.8192877 2.6503963 -5.56307 0.00015500475 -1.5698372 1.8341156 2.739595 -5.1385562 0.00015687623 -1.5564282 1.8562127 2.501214 -0.78716052 0.00015882836 -1.5427607 1.8773714 2.3435865 2.8472436 0.00016039372 -1.5288002 1.8956652 2.2980392 5.6595326 0.00016232841 -1.5145361 1.9093733 2.6414426 2.3517865 0.00016365345 -1.4999657 1.9260694 2.8047512 1.689443 0.00016566139 -1.4850839 1.9527455 2.5169865 7.6460826 0.00016641569 -1.4698449 1.9750883 2.5025928 9.8837033 0.00017034911 -1.4541516 1.9847568 3.1504806 4.2753172 0.00017141782"
    s = s + " -1.438104 2.0099117 3.2157148 4.8328179 0.00017448019 -1.4215628 2.0239976 3.8039014 -0.28153304 0.00017656234 -1.4046128 2.0543491 3.5563272 5.7751371 0.0001769942 -1.38714 2.0916555 3.0732965 14.767552 0.00017892036 -1.3690755 2.1113911 3.4866191 12.462613 0.00018268588 -1.3503417 2.1236448 4.3946426 2.4200196 0.00018601054 -1.3310719 2.1629672 4.0026267 9.9316285 0.000187214 -1.3111432 2.1994885 4.0790645 10.240756 0.00019061032 -1.2904021 2.2420436 3.7791777 15.485402 0.00019388647 -1.2689099 2.3008585 3.000574 25.4151 0.00019911109"
    s = s + " -1.2464024 2.32862 3.7709529 17.058953 0.00020395617 -1.2228862 2.3634295 4.2775097 11.250807 0.0002094463 -1.1982425 2.4090033 4.3932276 8.9032503 0.00021405604 -1.1723118 2.4458887 4.756895 6.8177565 0.00022029962 -1.1450172 2.4912967 5.0152698 2.9440321 0.00022563475 -1.1161953 2.5419524 5.0310148 2.6089919 0.00023322639 -1.0856992 2.6004777 4.6951057 7.8180145 0.00024328614 -1.0532375 2.684496 3.174349 24.984198 0.00025189864 -1.0185068 2.760494 2.2321465 34.995579 0.00026108219 -0.98105983 2.8205207 1.8424027 42.493438 0.00027192017"
    s = s + " -0.94030112 2.8636585 2.365293 34.26805 0.00028174168 -0.89611941 2.9410406 1.5984543 44.446099 0.00029244718 -0.84734516 3.0284974 0.36655117 60.86628 0.00030364579 -0.79301687 3.1032474 -0.070383002 67.919785 0.0003225959 -0.73134643 3.1699769 0.57238705 56.455304 0.00034359911 -0.65988222 3.2397533 1.0038603 55.590683 0.00036281585 -0.57498908 3.3704549 -0.86853477 90.162869 0.00040371043 -0.46882616 3.4565692 1.0856959 73.944809 0.00045839375 -0.32542503 3.6467386 0.97278076 80.096055 0.00053559421 -0.28927049 3.6667954 2.6798444 58.498617 0.00054654176"
    s = s + " -0.24936161 3.7425553 1.9014721 69.517502 0.00056565084 -0.20449854 3.8183521 1.2114951 81.493244 0.00059004685 -0.15389825 3.8686285 3.7704385 48.132614 0.00063012289 -0.094616438 3.9007553 8.2410287 -17.45936 0.00066143145 -0.023862549 4.0207808 7.1436152 20.57007 0.00075075038 0.065520718 4.1594945 6.7479375 46.321645 0.00082719858 0.1883404 4.3459788 9.7447054 8.0854981 0.00096268852 0.38863151 4.6531364 14.968841 -8.3553453 0.0013263463 0.57587025 5.070594 21.732595 -63.042215 0.0017499956 0.81904547 5.2559469 56.007846 -411.78944 0.0026299291"
    s = s + " 0.97720956 6.6104917 32.425153 -157.35229 0.0034296861"
    v = strtoreal(tokens(s))
    return(rowshape(v, 221))
}

real matrix bu_urc_probs()
{
    string scalar s
    real rowvector v
    s = ""
    s = s + " 1e-04 -3.71901649 2e-04 -3.5400838 5e-04 -3.29052673 0.001 -3.09023231 0.002 -2.87816174 0.003 -2.74778139 0.004 -2.65206981 0.005 -2.5758293 0.006 -2.51214433 0.007 -2.45726339"
    s = s + " 0.008 -2.40891555 0.009 -2.36561813 0.01 -2.32634787 0.015 -2.17009038 0.02 -2.05374891 0.025 -1.95996398 0.03 -1.88079361 0.035 -1.81191067 0.04 -1.75068607 0.045 -1.69539771"
    s = s + " 0.05 -1.64485363 0.055 -1.59819314 0.06 -1.55477359 0.065 -1.51410189 0.07 -1.47579103 0.075 -1.43953147 0.08 -1.40507156 0.085 -1.37220381 0.09 -1.34075503 0.095 -1.31057911"
    s = s + " 0.1 -1.28155157 0.105 -1.25356544 0.11 -1.22652812 0.115 -1.20035886 0.12 -1.17498679 0.125 -1.15034938 0.13 -1.12639113 0.135 -1.10306256 0.14 -1.08031934 0.145 -1.05812162"
    s = s + " 0.15 -1.03643339 0.155 -1.01522203 0.16 -0.99445788 0.165 -0.97411388 0.17 -0.95416525 0.175 -0.93458929 0.18 -0.91536509 0.185 -0.89647336 0.19 -0.8778963 0.195 -0.85961736"
    s = s + " 0.2 -0.84162123 0.205 -0.82389363 0.21 -0.80642125 0.215 -0.78919165 0.22 -0.77219321 0.225 -0.75541503 0.23 -0.73884685 0.235 -0.72247905 0.24 -0.70630256 0.245 -0.69030882"
    s = s + " 0.25 -0.67448975 0.255 -0.65883769 0.26 -0.64334541 0.265 -0.62800601 0.27 -0.61281299 0.275 -0.59776013 0.28 -0.58284151 0.285 -0.5680515 0.29 -0.55338472 0.295 -0.53883603"
    s = s + " 0.3 -0.52440051 0.305 -0.51007346 0.31 -0.49585035 0.315 -0.48172685 0.32 -0.4676988 0.325 -0.45376219 0.33 -0.43991317 0.335 -0.42614801 0.34 -0.41246313 0.345 -0.39885507"
    s = s + " 0.35 -0.38532047 0.355 -0.37185609 0.36 -0.35845879 0.365 -0.34512553 0.37 -0.33185335 0.375 -0.31863936 0.38 -0.30548079 0.385 -0.2923749 0.39 -0.27931903 0.395 -0.26631061"
    s = s + " 0.4 -0.2533471 0.405 -0.24042603 0.41 -0.22754498 0.415 -0.21470157 0.42 -0.20189348 0.425 -0.18911843 0.43 -0.17637416 0.435 -0.16365849 0.44 -0.15096922 0.445 -0.13830421"
    s = s + " 0.45 -0.12566135 0.455 -0.11303854 0.46 -0.10043372 0.465 -0.08784484 0.47 -0.07526986 0.475 -0.06270678 0.48 -0.05015358 0.485 -0.03760829 0.49 -0.02506891 0.495 -0.01253347"
    s = s + " 0.5 0 0.505 0.01253347 0.51 0.02506891 0.515 0.03760829 0.52 0.05015358 0.525 0.06270678 0.53 0.07526986 0.535 0.08784484 0.54 0.10043372 0.545 0.11303854"
    s = s + " 0.55 0.12566135 0.555 0.13830421 0.56 0.15096922 0.565 0.16365849 0.57 0.17637416 0.575 0.18911843 0.58 0.20189348 0.585 0.21470157 0.59 0.22754498 0.595 0.24042603"
    s = s + " 0.6 0.2533471 0.605 0.26631061 0.61 0.27931903 0.615 0.2923749 0.62 0.30548079 0.625 0.31863936 0.63 0.33185335 0.635 0.34512553 0.64 0.35845879 0.645 0.37185609"
    s = s + " 0.65 0.38532047 0.655 0.39885507 0.66 0.41246313 0.665 0.42614801 0.67 0.43991317 0.675 0.45376219 0.68 0.4676988 0.685 0.48172685 0.69 0.49585035 0.695 0.51007346"
    s = s + " 0.7 0.52440051 0.705 0.53883603 0.71 0.55338472 0.715 0.5680515 0.72 0.58284151 0.725 0.59776013 0.73 0.61281299 0.735 0.62800601 0.74 0.64334541 0.745 0.65883769"
    s = s + " 0.75 0.67448975 0.755 0.69030882 0.76 0.70630256 0.765 0.72247905 0.77 0.73884685 0.775 0.75541503 0.78 0.77219321 0.785 0.78919165 0.79 0.80642125 0.795 0.82389363"
    s = s + " 0.8 0.84162123 0.805 0.85961736 0.81 0.8778963 0.815 0.89647336 0.82 0.91536509 0.825 0.93458929 0.83 0.95416525 0.835 0.97411388 0.84 0.99445788 0.845 1.01522203"
    s = s + " 0.85 1.03643339 0.855 1.05812162 0.86 1.08031934 0.865 1.10306256 0.87 1.12639113 0.875 1.15034938 0.88 1.17498679 0.885 1.20035886 0.89 1.22652812 0.895 1.25356544"
    s = s + " 0.9 1.28155157 0.905 1.31057911 0.91 1.34075503 0.915 1.37220381 0.92 1.40507156 0.925 1.43953147 0.93 1.47579103 0.935 1.51410189 0.94 1.55477359 0.945 1.59819314"
    s = s + " 0.95 1.64485363 0.955 1.69539771 0.96 1.75068607 0.965 1.81191067 0.97 1.88079361 0.975 1.95996398 0.98 2.05374891 0.985 2.17009038 0.99 2.32634787 0.991 2.36561813"
    s = s + " 0.992 2.40891555 0.993 2.45726339 0.994 2.51214433 0.995 2.5758293 0.996 2.65206981 0.997 2.74778139 0.998 2.87816174 0.999 3.09023231 0.9995 3.29052673 0.9998 3.5400838"
    s = s + " 0.9999 3.71901649"
    v = strtoreal(tokens(s))
    return(rowshape(v, 221))
}

// MacKinnon (1996) p-value for a unit-root t-statistic.
// cs: "nc","c","ct" ; nobs: sample size for the response surface (0 = asymptotic)
real scalar bu_fpval(real scalar stat, string scalar cs, real scalar nobs)
{
    real matrix beta, pc, X, W
    real colvector crits, probs, cnorm, wght, yv, g
    real scalar i, np, nph, ic, np1, np2, nvar, eta, z

    if (cs=="nc") {
        beta = bu_urc_nc()
        nvar = 3
    }
    else if (cs=="c") {
        beta = bu_urc_c()
        nvar = 3
    }
    else {
        beta = bu_urc_ct()
        nvar = 4
    }
    pc    = bu_urc_probs()
    probs = pc[.,1]
    cnorm = pc[.,2]
    wght  = beta[., cols(beta)]

    crits = beta[.,1]
    if (nobs > 0) {
        eta = 1/nobs
        crits = crits + beta[.,2]*eta + beta[.,3]*(eta*eta)
        if (nvar==4) crits = crits + beta[.,4]*(eta*eta*eta)
    }

    np  = 9
    nph = 4
    ic = 222
    for (i=1; i<=221; i++) {
        if (crits[i] > stat) {
            ic = i
            i = 222
        }
    }
    np1 = ic - nph
    if (np1 < 1) np1 = 1
    np2 = np1 + np - 1
    if (np2 > 221) {
        np2 = 221
        np1 = np2 - np + 1
    }

    X  = J(np,4,1)
    yv = J(np,1,0)
    W  = J(np,1,0)
    for (i=1; i<=np; i++) {
        X[i,2] = crits[np1+i-1]
        X[i,3] = crits[np1+i-1]*crits[np1+i-1]
        X[i,4] = crits[np1+i-1]*crits[np1+i-1]*crits[np1+i-1]
        yv[i]  = cnorm[np1+i-1]
        W[i]   = 1/(wght[np1+i-1]*wght[np1+i-1])
    }
    g = invsym(cross(X,W,X)) * cross(X,W,yv)
    z = g[1] + g[2]*stat + g[3]*stat*stat + g[4]*stat*stat*stat
    return(normal(z))
}

// <<<END MACKINNON>>>

end
