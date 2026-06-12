*! version 1.0.0  10jun2026
*! xtdynestimb -- Dynamic linear panel-data estimators robust to structural
*!                breaks, long-T overidentification, and error cross-sectional
*!                dependence
*! Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
*!         https://github.com/merwanroudane
*! Subcommands (estimators):
*!   dd      Chowdhury & Russell (2017) Difference / System / 'Double-D' GMM
*!             panel estimators in the presence of structural breaks.
*!             variant(): difference | system | ddback | ddforward | full
*!             Moment conditions (their Table 1):
*!               (1) E[y_{i,t-s} Dv_it]        = 0   (Arellano-Bond levels-as-IV)
*!               (2) E[Dy_{i,t-1}(v_it+eta_i)] = 0   (Blundell-Bond level eq)
*!               (3) E[Dy_{i,t-s} Dv_it]       = 0,  S>=2  (backward double-D)
*!               (4) E[Dy_{i,t+s} Dv_it]       = 0,  S>=2  (forward  double-D)
*!   csdgmm  Sarafidis (2009) GMM estimation of short dynamic panels with error
*!             cross-sectional dependence: cross-sectional (time) demeaning to
*!             purge common factors, then difference/system GMM; partial
*!             (regressor-only) instruments option robust to heterogeneous CSD.
*!   ablasso Chernozhukov, Fernandez-Val, Huang & Wang (2024) Arellano-Bond
*!             LASSO estimator for long-T dynamic panels: per-period LASSO
*!             selection of the most informative moment conditions + IV, with
*!             optional cross-fitting / sample-splitting (AB-LASSO-SS).
*! Companion to xtdyntest (specification tests). Self-contained Mata engine;
*! no dependency on xtabond2/xtdpdgmm/xtdpd.

program xtdynestimb, eclass
    version 16.0
    if replay() {
        if "`e(cmd)'" != "xtdynestimb" {
            di as error "last estimates not found"
            exit 301
        }
        _xde_display
        exit
    }
    gettoken sub 0 : 0, parse(" ,")
    if `"`sub'"' == "" {
        di as error "subcommand required"
        di as error "  syntax: {bf:xtdynestimb} {it:subcommand} {it:depvar} [indepvars] [, options]"
        di as error "  subcommands: {bf:dd}, {bf:csdgmm}, {bf:ablasso}, {bf:graph}"
        exit 198
    }
    if "`sub'" == "dd" {
        _xde_dd `0'
    }
    else if "`sub'" == "csdgmm" {
        _xde_csdgmm `0'
    }
    else if "`sub'" == "ablasso" {
        _xde_ablasso `0'
    }
    else if "`sub'" == "dabss" {
        _xde_dabss `0'
    }
    else if "`sub'" == "breaks" {
        _xde_breaks `0'
    }
    else if "`sub'" == "table" {
        _xde_table `0'
    }
    else if "`sub'" == "graph" {
        _xde_graph `0'
    }
    else {
        di as error `"unknown subcommand "`sub'""'
        di as error "  available: dd, csdgmm, ablasso, dabss, breaks, table, graph"
        exit 198
    }
end

*=======================================================================
* dabss : Debiased Arellano-Bond via split-panel (cross-section)
*   jackknife (Chen, Chernozhukov & Fernandez-Val 2019).
*=======================================================================
program _xde_dabss, eclass
    version 16.0
    syntax varlist(numeric ts min=1) [if] [in] [ , ///
        Lags(integer 1) GMMLags(numlist min=2 max=2 integer) ///
        ONEstep noWINdmeijer GRAPH GRAPHname(string) noTABle LEVEL(cilevel) ]

    quietly xtset
    local id   "`r(panelvar)'"
    local time "`r(timevar)'"
    if "`id'" == "" | "`time'" == "" {
        di as error "data are not {bf:xtset}"
        exit 459
    }
    if `lags' < 1 {
        di as error "lags() must be a positive integer (AR order)"
        exit 198
    }
    gettoken depvar exog : varlist
    local kx : word count `exog'
    local two  = cond("`onestep'" != "", 0, 1)
    local wind = cond("`windmeijer'" == "nowindmeijer", 0, 1)
    if !`two' local wind 0
    if "`gmmlags'" == "" local gmmlags "2 ."
    tokenize "`gmmlags'"
    local gmin "`1'"
    local gmax "`2'"
    if "`gmin'" == "" | "`gmin'" == "." local gmin 2
    if "`gmax'" == "" | "`gmax'" == "." local gmax 9999

    marksample touse
    markout `touse' `depvar' `exog' `id' `time'
    quietly count if `touse'
    if r(N) == 0 {
        di as error "no usable observations"
        exit 2000
    }
    sort `id' `time'

    tempname b V
    mata: _xde_dab_run("`depvar'", "`exog'", "`id'", "`time'", "`touse'", ///
        `lags', `kx', `gmin', `gmax', `two', `wind', "`b'", "`V'")
    if __xde_rc != 0 {
        local rc = __xde_rc
        capture scalar drop __xde_rc
        if `rc' == 1 di as error "too few units to split the cross-section in half"
        else         di as error "estimation failed (rc=`rc')"
        exit 198
    }

    _xde_postest, b(`b') v(`V') depvar(`depvar') exog(`exog') lags(`lags') ///
        id(`id') time(`time') touse(`touse') level(`level') ///
        subcmd(dabss) estimator("Debiased Arellano-Bond (split-panel SS, Chen et al. 2019)")
    ereturn local  step     = cond(`two', "two-step", "one-step")
    ereturn local  vce      "AB analytic (split-panel jackknife point estimate)"
    ereturn local  gmmlags  "`gmin' `gmax'"

    if "`table'" != "notable" _xde_display
    if "`graph'" != "" _xde_graph, name(`graphname')
end

*=======================================================================
* breaks : Bai-Perron mean-break detection on the cross-sectional mean
*   of depvar -- reproduces the Table A1 regime step (Chowdhury-Russell).
*=======================================================================
program _xde_breaks, rclass
    version 16.0
    syntax varname(numeric) [if] [in] [ , ///
        MAXbreaks(integer 5) MINlength(integer 0) noTABle ]

    quietly xtset
    local id   "`r(panelvar)'"
    local time "`r(timevar)'"
    if "`id'" == "" | "`time'" == "" {
        di as error "data are not {bf:xtset}"
        exit 459
    }
    marksample touse
    markout `touse' `varlist' `id' `time'
    quietly count if `touse'
    if r(N) == 0 {
        di as error "no usable observations"
        exit 2000
    }
    sort `id' `time'

    tempname R
    mata: _xde_breaks_run("`varlist'", "`time'", "`touse'", `maxbreaks', ///
        `minlength', "`R'")
    local nb     = __xde_nbreaks
    local nreg   = __xde_nreg
    local minlen = __xde_minlen
    capture scalar drop __xde_nbreaks __xde_nreg __xde_minlen

    if "`table'" != "notable" {
        di ""
        di as txt "{hline 64}"
        di as txt "Estimated breaks in " as result "`varlist'" as txt " (Bai-Perron, BIC-selected)"
        di as txt "Cross-sectional mean series; min regime length = " as result "`minlen'" as txt " periods"
        di as txt "{hline 64}"
        di as txt %-8s "Regime" %22s "Dates (`time')" %10s "Periods" %16s "Mean"
        di as txt "{hline 64}"
        forvalues r = 1/`nreg' {
            local rr = `R'[`r',1]
            local d1 = `R'[`r',2]
            local d2 = `R'[`r',3]
            local np = `R'[`r',4]
            local mn = `R'[`r',5]
            di as txt %-8.0f `rr' as result %14.0f `d1' as txt " - " as result %5.0f `d2' ///
                as result %10.0f `np' %16.4f `mn'
        }
        di as txt "{hline 64}"
        di as txt "Number of breaks detected: " as result "`nb'"
        di as txt "Method: Bai & Perron (1998) dynamic-programming partition of the"
        di as txt "        cross-sectional mean, number of breaks chosen by BIC."
        di as txt "Use these regimes to justify the break-robust estimators in"
        di as txt "{help xtdynestimb_dd:xtdynestimb dd} / {help xtdynestimb##table:xtdynestimb table}."
        di as txt "{hline 64}"
    }

    return matrix regimes = `R'
    return scalar nbreaks = `nb'
    return scalar nregimes = `nreg'
    return scalar minlength = `minlen'
end

*=======================================================================
* dd : Chowdhury & Russell (2017) Difference / System / Double-D GMM
*=======================================================================
program _xde_dd, eclass
    version 16.0
    syntax varlist(numeric ts min=1) [if] [in] [ , ///
        VARIANT(string) Lags(integer 1) ///
        GMMLags(numlist min=2 max=2 integer) ///
        TWOstep ONEstep noWINdmeijer ///
        COMPARE GRAPH GRAPHname(string) noTABle LEVEL(cilevel) ]

    quietly xtset
    local id   "`r(panelvar)'"
    local time "`r(timevar)'"
    if "`id'" == "" | "`time'" == "" {
        di as error "data are not {bf:xtset}; cannot identify panel/time"
        exit 459
    }
    if `lags' < 1 {
        di as error "lags() must be a positive integer (AR order)"
        exit 198
    }

    gettoken depvar exog : varlist
    local kx : word count `exog'

    if "`variant'" == "" local variant "full"
    local variant = strlower("`variant'")
    if      "`variant'" == "difference" | "`variant'" == "diff"     local vc 1
    else if "`variant'" == "system"     | "`variant'" == "sys"      local vc 2
    else if "`variant'" == "ddback"     | "`variant'" == "backward" local vc 3
    else if "`variant'" == "ddforward"  | "`variant'" == "forward"  local vc 4
    else if "`variant'" == "full"                                   local vc 5
    else {
        di as error "variant() must be one of: difference, system, ddback, ddforward, full"
        exit 198
    }

    if "`onestep'" != "" & "`twostep'" != "" {
        di as error "specify only one of {bf:onestep} or {bf:twostep}"
        exit 198
    }
    local two  = cond("`onestep'" != "", 0, 1)
    local wind = cond("`windmeijer'" == "nowindmeijer", 0, 1)
    if !`two' local wind 0

    if "`gmmlags'" == "" local gmmlags "2 ."
    tokenize "`gmmlags'"
    local gmin "`1'"
    local gmax "`2'"
    if "`gmin'" == "" | "`gmin'" == "." local gmin 2
    if "`gmax'" == "" | "`gmax'" == "." local gmax 9999
    if `gmin' < 2 {
        di as error "gmmlags() minimum lag must be >= 2 (lower lags are not valid instruments)"
        exit 198
    }

    if "`compare'" != "" {
        _xde_dd_compare `varlist' `if' `in', lags(`lags') gmin(`gmin') ///
            gmax(`gmax') two(`two') wind(`wind') level(`level') ///
            id(`id') time(`time') `graph' graphname(`graphname')
        exit
    }

    marksample touse
    markout `touse' `depvar' `exog' `id' `time'
    quietly count if `touse'
    if r(N) == 0 {
        di as error "no usable observations"
        exit 2000
    }
    sort `id' `time'

    tempname b V
    mata: _xde_dd_run("`depvar'", "`exog'", "`id'", "`time'", "`touse'", ///
        `lags', `kx', `vc', `gmin', `gmax', `two', `wind', "`b'", "`V'")
    if __xde_rc != 0 {
        local rc = __xde_rc
        capture scalar drop __xde_rc
        if `rc' == 2 di as error "model is not identified: instruments <= parameters; widen gmmlags() or change variant()"
        else         di as error "estimation failed (rc=`rc'); too few usable periods?"
        exit 198
    }

    _xde_postest, b(`b') v(`V') depvar(`depvar') exog(`exog') lags(`lags') ///
        id(`id') time(`time') touse(`touse') level(`level') ///
        subcmd(dd) estimator("Double-D GMM (Chowdhury-Russell 2017)")
    ereturn local  variant  "`variant'"
    ereturn local  step     = cond(`two', "two-step", "one-step")
    ereturn local  vce      = cond(`two' & `wind', "WC-robust", "robust")
    ereturn local  gmmlags  "`gmin' `gmax'"

    if "`table'" != "notable" _xde_display
    if "`graph'" != "" _xde_graph, name(`graphname')
end

*=======================================================================
* csdgmm : Sarafidis (2009) CSD-robust GMM (time-demean + diff/system)
*=======================================================================
program _xde_csdgmm, eclass
    version 16.0
    syntax varlist(numeric ts min=1) [if] [in] [ , ///
        VARIANT(string) Lags(integer 1) ///
        GMMLags(numlist min=2 max=2 integer) ///
        PARTIAL noDEMean TWOstep ONEstep noWINdmeijer ///
        GRAPH GRAPHname(string) noTABle LEVEL(cilevel) ]

    quietly xtset
    local id   "`r(panelvar)'"
    local time "`r(timevar)'"
    if "`id'" == "" | "`time'" == "" {
        di as error "data are not {bf:xtset}; cannot identify panel/time"
        exit 459
    }
    if `lags' < 1 {
        di as error "lags() must be a positive integer (AR order)"
        exit 198
    }

    gettoken depvar exog : varlist
    local kx : word count `exog'

    if "`variant'" == "" local variant "system"
    local variant = strlower("`variant'")
    if      "`variant'" == "difference" | "`variant'" == "diff" local vc 1
    else if "`variant'" == "system"     | "`variant'" == "sys"  local vc 2
    else {
        di as error "variant() must be one of: difference, system"
        exit 198
    }
    if "`partial'" != "" & `kx' == 0 {
        di as error "partial requires at least one regressor (indepvars) to use as the only instruments"
        exit 198
    }
    local par = cond("`partial'" != "", 1, 0)
    local dem = cond("`demean'" == "nodemean", 0, 1)

    if "`onestep'" != "" & "`twostep'" != "" {
        di as error "specify only one of {bf:onestep} or {bf:twostep}"
        exit 198
    }
    local two  = cond("`onestep'" != "", 0, 1)
    local wind = cond("`windmeijer'" == "nowindmeijer", 0, 1)
    if !`two' local wind 0

    if "`gmmlags'" == "" local gmmlags "2 ."
    tokenize "`gmmlags'"
    local gmin "`1'"
    local gmax "`2'"
    if "`gmin'" == "" | "`gmin'" == "." local gmin 2
    if "`gmax'" == "" | "`gmax'" == "." local gmax 9999
    if `gmin' < 2 {
        di as error "gmmlags() minimum lag must be >= 2"
        exit 198
    }

    marksample touse
    markout `touse' `depvar' `exog' `id' `time'
    quietly count if `touse'
    if r(N) == 0 {
        di as error "no usable observations"
        exit 2000
    }
    sort `id' `time'

    tempname b V
    mata: _xde_csd_run("`depvar'", "`exog'", "`id'", "`time'", "`touse'", ///
        `lags', `kx', `vc', `gmin', `gmax', `par', `dem', `two', `wind', "`b'", "`V'")
    if __xde_rc != 0 {
        local rc = __xde_rc
        capture scalar drop __xde_rc
        if `rc' == 2 di as error "model is not identified: instruments <= parameters"
        else         di as error "estimation failed (rc=`rc')"
        exit 198
    }

    _xde_postest, b(`b') v(`V') depvar(`depvar') exog(`exog') lags(`lags') ///
        id(`id') time(`time') touse(`touse') level(`level') ///
        subcmd(csdgmm) estimator("CSD-robust GMM (Sarafidis 2009)")
    ereturn local  variant  "`variant'"
    ereturn local  step     = cond(`two', "two-step", "one-step")
    ereturn local  vce      = cond(`two' & `wind', "WC-robust", "robust")
    ereturn local  gmmlags  "`gmin' `gmax'"
    ereturn local  demean   = cond(`dem', "time-demeaned (CSD-robust)", "raw (no demeaning)")
    ereturn local  partial  = cond(`par', "regressor-only instruments", "standard instruments")

    if "`table'" != "notable" _xde_display
    if "`graph'" != "" _xde_graph, name(`graphname')
end

*=======================================================================
* ablasso : Chernozhukov-Fernandez-Val-Huang-Wang (2024) AB-LASSO
*=======================================================================
program _xde_ablasso, eclass
    version 16.0
    syntax varlist(numeric ts min=1) [if] [in] [ , ///
        Lags(integer 1) CROSSfit KFold(integer 2) NSplits(integer 1) ///
        LAMBda(real -1) Cons(real 1.1) SEED(string) ///
        GRAPH GRAPHname(string) noTABle LEVEL(cilevel) ]

    quietly xtset
    local id   "`r(panelvar)'"
    local time "`r(timevar)'"
    if "`id'" == "" | "`time'" == "" {
        di as error "data are not {bf:xtset}; cannot identify panel/time"
        exit 459
    }
    if `lags' < 1 {
        di as error "lags() must be a positive integer (AR order)"
        exit 198
    }

    gettoken depvar exog : varlist
    local kx : word count `exog'

    local cf = cond("`crossfit'" != "", 1, 0)
    if `cf' & `kfold' < 2 {
        di as error "kfold() must be >= 2 when crossfit is specified"
        exit 198
    }
    if `nsplits' < 1 {
        di as error "nsplits() must be >= 1"
        exit 198
    }
    if "`seed'" != "" set seed `seed'

    marksample touse
    markout `touse' `depvar' `exog' `id' `time'
    quietly count if `touse'
    if r(N) == 0 {
        di as error "no usable observations"
        exit 2000
    }
    sort `id' `time'

    tempname b V
    mata: _xde_abl_run("`depvar'", "`exog'", "`id'", "`time'", "`touse'", ///
        `lags', `kx', `cf', `kfold', `nsplits', `lambda', `cons', "`b'", "`V'")
    if __xde_rc != 0 {
        local rc = __xde_rc
        capture scalar drop __xde_rc
        if `rc' == 3 di as error "no instruments selected by LASSO at any period; lower lambda() or check data"
        else if `rc' == 2 di as error "model is not identified after instrument selection"
        else         di as error "estimation failed (rc=`rc'); is T large enough for AB-LASSO?"
        exit 198
    }

    local Tmax  = __xde_Tmax
    local navg  = __xde_navg
    local lam   = __xde_lam
    _xde_postest, b(`b') v(`V') depvar(`depvar') exog(`exog') lags(`lags') ///
        id(`id') time(`time') touse(`touse') level(`level') ///
        subcmd(ablasso) estimator("Arellano-Bond LASSO (Chernozhukov et al. 2024)")
    ereturn scalar Tmax     = `Tmax'
    ereturn scalar n_selavg = `navg'
    ereturn scalar lambda   = `lam'
    ereturn local  vce      "cluster-robust (panel)"
    ereturn local  crossfit = cond(`cf', "cross-fitting (AB-LASSO-SS), K=`kfold', `nsplits' split(s)", "no cross-fitting (AB-LASSO)")
    capture scalar drop __xde_Tmax __xde_navg __xde_lam

    if "`table'" != "notable" _xde_display
    if "`graph'" != "" _xde_graph, name(`graphname')
end

*=======================================================================
* Shared e()-posting for the GMM estimators
*=======================================================================
program _xde_postest, eclass
    syntax , b(name) v(name) depvar(string) lags(integer) id(string) ///
        time(string) touse(string) level(cilevel) subcmd(string) ///
        estimator(string) [ exog(string) ]

    local cn ""
    forvalues l = 1/`lags' {
        local cn "`cn' L`l'.`depvar'"
    }
    foreach vv of local exog {
        local cn "`cn' `vv'"
    }
    matrix colnames `b' = `cn'
    matrix rownames `b' = `depvar'
    matrix colnames `v' = `cn'
    matrix rownames `v' = `cn'

    local N    = __xde_N
    local Ng   = __xde_Ng
    capture local M   = __xde_M
    if _rc local M .
    capture local J   = __xde_J
    if _rc local J .
    capture local Jdf = __xde_Jdf
    if _rc local Jdf .
    capture local ar1 = __xde_ar1
    if _rc local ar1 .
    capture local ar2 = __xde_ar2
    if _rc local ar2 .
    foreach s in N Ng M J Jdf ar1 ar2 rc {
        capture scalar drop __xde_`s'
    }

    ereturn post `b' `v', esample(`touse') depname(`depvar')
    ereturn scalar N        = `N'
    ereturn scalar N_g      = `Ng'
    if `M' != . ereturn scalar n_moments = `M'
    if `J' != . {
        ereturn scalar j     = `J'
        ereturn scalar j_df  = `Jdf'
        ereturn scalar j_p   = chi2tail(`Jdf', `J')
    }
    if `ar1' != . {
        ereturn scalar ar1   = `ar1'
        ereturn scalar ar1_p = 2*normal(-abs(`ar1'))
    }
    if `ar2' != . {
        ereturn scalar ar2   = `ar2'
        ereturn scalar ar2_p = 2*normal(-abs(`ar2'))
    }
    ereturn scalar arlags   = `lags'
    ereturn scalar level    = `level'
    ereturn local  estimator "`estimator'"
    ereturn local  indepvars "`exog'"
    ereturn local  ivar     "`id'"
    ereturn local  tvar     "`time'"
    ereturn local  depvar   "`depvar'"
    ereturn local  predict  "xtdynestimb_predict"
    ereturn local  cmd      "xtdynestimb"
    ereturn local  subcmd   "`subcmd'"
end

*=======================================================================
* Display
*=======================================================================
program _xde_display
    version 16.0
    local sub "`e(subcmd)'"
    di ""
    di as txt "{hline 78}"
    if "`sub'" == "dd" {
        di as txt "Double-D dynamic panel GMM" _col(52) "{help xtdynestimb##dd:help dd}"
    }
    else if "`sub'" == "csdgmm" {
        di as txt "CSD-robust dynamic panel GMM" _col(52) "{help xtdynestimb##csdgmm:help csdgmm}"
    }
    else if "`sub'" == "dabss" {
        di as txt "Debiased Arellano-Bond (split-panel jackknife)" _col(52) "{help xtdynestimb##dabss:help dabss}"
    }
    else {
        di as txt "Arellano-Bond LASSO dynamic panel estimator" _col(52) "{help xtdynestimb##ablasso:help ablasso}"
    }
    di as txt "{hline 78}"
    di as txt "Estimator        : " as result "`e(estimator)'"
    di as txt "Dependent var.   : " as result "`e(depvar)'" as txt "    Panel: " as result "`e(ivar)'" as txt ", time: " as result "`e(tvar)'"
    di as txt "Groups (N)       : " as result %9.0g e(N_g) as txt "    Obs used (NT): " as result %9.0g e(N)
    if "`sub'" == "dd" {
        di as txt "Variant          : " as result "`e(variant)'" as txt "   AR order: " as result e(arlags) as txt "   step: " as result "`e(step)'"
        di as txt "Instruments      : " as result e(n_moments) as txt " moments (gmm lag window `e(gmmlags)')"
    }
    else if "`sub'" == "csdgmm" {
        di as txt "Variant          : " as result "`e(variant)'" as txt "   AR order: " as result e(arlags) as txt "   step: " as result "`e(step)'"
        di as txt "Transform        : " as result "`e(demean)'"
        di as txt "Instruments      : " as result e(n_moments) as txt " moments (`e(partial)')"
    }
    else if "`sub'" == "dabss" {
        di as txt "Method           : " as result "split-panel (cross-section half) jackknife of AB"
        di as txt "AR order         : " as result e(arlags) as txt "   step: " as result "`e(step)'" as txt "   gmm lags: " as result "`e(gmmlags)'"
    }
    else {
        local lamtxt = cond(e(lambda) < 0, "plug-in", string(e(lambda), "%6.2f"))
        di as txt "AR order         : " as result e(arlags) as txt "   T(max): " as result e(Tmax)
        di as txt "Selection        : " as result "`e(crossfit)'"
        di as txt "Avg # selected   : " as result %6.2f e(n_selavg) as txt " inst./period   (lambda = " as result "`lamtxt'" as txt ")"
    }
    di as txt "{hline 78}"
    ereturn display, level(`e(level)')
    if e(j) < . {
        di as txt "Hansen J = " as result %7.3f e(j) as txt " (df " as result e(j_df) ///
            as txt "), p = " as result %6.4f e(j_p) ///
            as txt "   {it:H0: overidentifying restrictions valid}"
    }
    if e(ar1) < . {
        di as txt "Arellano-Bond AR(1) z = " as result %7.3f e(ar1) ///
            as txt ", p = " as result %6.4f e(ar1_p) ///
            as txt "    AR(2) z = " as result %7.3f e(ar2) ///
            as txt ", p = " as result %6.4f e(ar2_p)
        di as txt "   {it:H0: no serial correlation of that order in differenced errors}"
    }
    di as txt "VCE: " as result "`e(vce)'"
    di as txt "{hline 78}"
end

*=======================================================================
* table : journal-style empirical comparison across estimators
*   (Chowdhury & Russell 2017, Table 7 layout): columns = estimators,
*   rows = coefficients (stars + se) then a diagnostics block
*   (N, groups, instruments, Hansen J p, AR(1) p, AR(2) p).
*=======================================================================
program _xde_table, rclass
    version 16.0
    syntax varlist(numeric ts min=1) [if] [in] [ , ///
        Lags(integer 1) GMMLags(numlist min=2 max=2 integer) ///
        ESTimators(string) ONEstep noWINdmeijer LEVEL(cilevel) ///
        TITLE(string) LONGrun SRLR NSplits(integer 5) ///
        BREAKS MAXbreaks(integer 5) MINlength(integer 0) ]

    quietly xtset
    local id   "`r(panelvar)'"
    local time "`r(timevar)'"
    if "`id'" == "" | "`time'" == "" {
        di as error "data are not {bf:xtset}"
        exit 459
    }
    gettoken depvar exog : varlist
    local kx : word count `exog'
    local k  = `lags' + `kx'

    if "`estimators'" == "" local estimators "difference system ddback ddforward full"
    local two  = cond("`onestep'" != "", 0, 1)
    local wind = cond("`windmeijer'" == "nowindmeijer", 0, 1)
    if !`two' local wind 0
    if "`gmmlags'" == "" local gmmlags "2 ."
    tokenize "`gmmlags'"
    local gmin "`1'"
    local gmax "`2'"
    if "`gmin'" == "" | "`gmin'" == "." local gmin 2
    if "`gmax'" == "" | "`gmax'" == "." local gmax 9999

    marksample touse
    markout `touse' `depvar' `exog' `id' `time'
    sort `id' `time'

    local cn ""
    forvalues l = 1/`lags' {
        local cn "`cn' L`l'.`depvar'"
    }
    foreach v of local exog {
        local cn "`cn' `v'"
    }

    local E : word count `estimators'
    tempname B S BL SL D
    matrix `B'  = J(`k', `E', .)
    matrix `S'  = J(`k', `E', .)
    matrix `BL' = J(`k', `E', .)
    matrix `SL' = J(`k', `E', .)
    matrix `D'  = J(6, `E', .)

    local col 0
    foreach est of local estimators {
        local ++col
        tempname b V
        capture scalar drop __xde_rc
        *--- dispatch on estimator name ---
        if "`est'" == "difference" {
            local lab`col' "Difference"
            capture mata: _xde_dd_run("`depvar'","`exog'","`id'","`time'","`touse'",`lags',`kx',1,`gmin',`gmax',`two',`wind',"`b'","`V'")
        }
        else if "`est'" == "ab" {
            local lab`col' "AB"
            capture mata: _xde_dd_run("`depvar'","`exog'","`id'","`time'","`touse'",`lags',`kx',1,`gmin',`gmax',`two',`wind',"`b'","`V'")
        }
        else if "`est'" == "system" {
            local lab`col' "System"
            capture mata: _xde_dd_run("`depvar'","`exog'","`id'","`time'","`touse'",`lags',`kx',2,`gmin',`gmax',`two',`wind',"`b'","`V'")
        }
        else if "`est'" == "ddback" {
            local lab`col' "DD-back"
            capture mata: _xde_dd_run("`depvar'","`exog'","`id'","`time'","`touse'",`lags',`kx',3,`gmin',`gmax',`two',`wind',"`b'","`V'")
        }
        else if "`est'" == "ddforward" {
            local lab`col' "DD-fwd"
            capture mata: _xde_dd_run("`depvar'","`exog'","`id'","`time'","`touse'",`lags',`kx',4,`gmin',`gmax',`two',`wind',"`b'","`V'")
        }
        else if "`est'" == "full" {
            local lab`col' "Full"
            capture mata: _xde_dd_run("`depvar'","`exog'","`id'","`time'","`touse'",`lags',`kx',5,`gmin',`gmax',`two',`wind',"`b'","`V'")
        }
        else if "`est'" == "csdgmm" {
            local lab`col' "CSD-GMM"
            capture mata: _xde_csd_run("`depvar'","`exog'","`id'","`time'","`touse'",`lags',`kx',2,`gmin',`gmax',0,1,`two',`wind',"`b'","`V'")
        }
        else if "`est'" == "csdpartial" {
            local lab`col' "CSD-part"
            capture mata: _xde_csd_run("`depvar'","`exog'","`id'","`time'","`touse'",`lags',`kx',2,`gmin',`gmax',1,1,`two',`wind',"`b'","`V'")
        }
        else if "`est'" == "dabss" {
            local lab`col' "DAB-SS"
            capture mata: _xde_dab_run("`depvar'","`exog'","`id'","`time'","`touse'",`lags',`kx',`gmin',`gmax',`two',`wind',"`b'","`V'")
        }
        else if substr("`est'",1,7) == "ablasso" {
            local Kf = substr("`est'",8,.)
            if "`Kf'" == "" {
                local lab`col' "AB-LASSO"
                capture mata: _xde_abl_run("`depvar'","`exog'","`id'","`time'","`touse'",`lags',`kx',0,2,1,-1,1.1,"`b'","`V'")
            }
            else {
                local lab`col' "ABL(K=`Kf')"
                capture mata: _xde_abl_run("`depvar'","`exog'","`id'","`time'","`touse'",`lags',`kx',1,`Kf',`nsplits',-1,1.1,"`b'","`V'")
            }
        }
        else {
            di as error "unknown estimator in estimators(): `est'"
            di as error "  allowed: difference ab system ddback ddforward full csdgmm csdpartial dabss ablasso ablasso2 ablasso5 ..."
            exit 198
        }
        local mrc = _rc
        capture confirm scalar __xde_rc
        if _rc local erc 99
        else local erc = __xde_rc
        if `mrc' == 0 & `erc' == 0 {
            forvalues i = 1/`k' {
                matrix `B'[`i',`col'] = `b'[1,`i']
                matrix `S'[`i',`col'] = sqrt(`V'[`i',`i'])
            }
            if `kx' > 0 {
                local denom = 1
                forvalues l = 1/`lags' {
                    local denom = `denom' - `b'[1,`l']
                }
                if `denom' != 0 {
                    tempname gg vv
                    forvalues i = `=`lags'+1'/`k' {
                        matrix `gg' = J(`k',1,0)
                        forvalues l = 1/`lags' {
                            matrix `gg'[`l',1] = `b'[1,`i']/(`denom'^2)
                        }
                        matrix `gg'[`i',1] = 1/`denom'
                        matrix `vv' = `gg''*`V'*`gg'
                        matrix `BL'[`i',`col'] = `b'[1,`i']/`denom'
                        matrix `SL'[`i',`col'] = sqrt(`vv'[1,1])
                    }
                }
            }
            capture matrix `D'[1,`col'] = __xde_Ng
            capture matrix `D'[2,`col'] = __xde_N
            capture matrix `D'[3,`col'] = __xde_M
            capture matrix `D'[3,`col'] = __xde_navg
            capture matrix `D'[4,`col'] = chi2tail(__xde_Jdf, __xde_J)
            capture matrix `D'[5,`col'] = 2*normal(-abs(__xde_ar1))
            capture matrix `D'[6,`col'] = 2*normal(-abs(__xde_ar2))
        }
        foreach s in N Ng M J Jdf ar1 ar2 Tmax navg lam rc {
            capture scalar drop __xde_`s'
        }
    }

    *--- optional break/regime detection (Table A1 step) ----------------
    if "`breaks'" != "" {
        _xde_breaks `depvar' if `touse', maxbreaks(`maxbreaks') minlength(`minlength')
    }

    *--- print ----------------------------------------------------------
    if "`title'" == "" local title "Dynamic panel estimator comparison: `depvar'"
    local L 28
    local W 13
    local tot = `L' + `E'*`W'
    di ""
    di as txt "{hline `tot'}"
    di as txt "`title'"
    di as txt "Panel: `id', time: `time'   AR order: `lags'   gmm lags: `gmin' `gmax'"
    di as txt "{hline `tot'}"
    di as txt %-`L's "Variable" _continue
    forvalues c = 1/`E' {
        di as result %`W's "(`c') `lab`c''" _continue
    }
    di ""
    di as txt "{hline `tot'}"

    * AR-lag (persistence) coefficients -- short run
    forvalues i = 1/`lags' {
        local vname : word `i' of `cn'
        _xde_prow `B' `S' `i' `E' `W' `L' "`vname'"
    }
    * regressors
    if `kx' > 0 {
        if "`srlr'" != "" {
            forvalues i = `=`lags'+1'/`k' {
                local vname : word `i' of `cn'
                _xde_prow `B'  `S'  `i' `E' `W' `L' "`vname': Short-run"
                _xde_prow `BL' `SL' `i' `E' `W' `L' "   Long-run"
            }
        }
        else if "`longrun'" != "" {
            di as txt "{it:Long-run coefficients}"
            forvalues i = `=`lags'+1'/`k' {
                local vname : word `i' of `cn'
                _xde_prow `BL' `SL' `i' `E' `W' `L' "`vname'"
            }
        }
        else {
            forvalues i = `=`lags'+1'/`k' {
                local vname : word `i' of `cn'
                _xde_prow `B' `S' `i' `E' `W' `L' "`vname'"
            }
        }
    }

    di as txt "{hline `tot'}"
    di as txt "{it:Diagnostics}"
    local rlab1 "Units (N)"
    local rlab2 "Observations"
    local rlab3 "Instr. / avg sel."
    local rlab4 "Hansen J (p)"
    local rlab5 "AR(1) (p)"
    local rlab6 "AR(2) (p)"
    forvalues r = 1/6 {
        di as txt %-`L's "`rlab`r''" _continue
        forvalues c = 1/`E' {
            local val = `D'[`r',`c']
            if `val' == . {
                local cell "."
            }
            else if `r' <= 2 {
                local cell = string(`val', "%7.0f")
            }
            else if `r' == 3 {
                local cell = string(`val', "%7.1f")
            }
            else {
                local cell = string(`val', "%7.4f")
            }
            di as result %`W's "`cell'" _continue
        }
        di ""
    }
    di as txt "{hline `tot'}"
    di as txt "Coefficients with * p<.10, ** p<.05, *** p<.01; (std. err.) below."
    di as txt "Long-run effect = coef / (1 - sum of AR coefficients), delta-method s.e."
    di as txt "Hansen J: H0 = instruments valid.  AR(1)/AR(2): H0 = no serial corr."
    di as txt "DAB-SS = split-panel jackknife debiased AB (no overid J)."
    di as txt "{hline `tot'}"

    return matrix coef     = `B'
    return matrix se       = `S'
    if `kx' > 0 {
        return matrix coef_lr = `BL'
        return matrix se_lr   = `SL'
    }
    return local estimators "`estimators'"
end

* print one coefficient row (coef+stars, then (se) below) across columns
program _xde_prow
    gettoken Bmat 0 : 0
    gettoken Smat 0 : 0
    gettoken row  0 : 0
    gettoken E    0 : 0
    gettoken W    0 : 0
    gettoken L    0 : 0
    local vname `0'
    forvalues c = 1/`E' {
        local bb = `Bmat'[`row',`c']
        local ss = `Smat'[`row',`c']
        if `bb' == . {
            local c1`c' "."
            local c2`c' ""
        }
        else {
            local z = `bb'/`ss'
            local pp = 2*normal(-abs(`z'))
            local st ""
            if `pp' < .01 local st "***"
            else if `pp' < .05 local st "**"
            else if `pp' < .10 local st "*"
            local c1`c' = string(`bb',"%7.4f") + "`st'"
            local c2`c' = "(" + string(`ss',"%6.4f") + ")"
        }
    }
    di as txt %-`L's "`vname'" _continue
    forvalues c = 1/`E' {
        di as result %`W's "`c1`c''" _continue
    }
    di ""
    di as txt %-`L's "" _continue
    forvalues c = 1/`E' {
        di as result %`W's "`c2`c''" _continue
    }
    di ""
end

*=======================================================================
* dd compare : estimate all 5 variants, tabulate the persistence coef
*=======================================================================
program _xde_dd_compare, rclass
    version 16.0
    syntax varlist(numeric ts) [if] [in], lags(integer) gmin(integer) ///
        gmax(integer) two(integer) wind(integer) level(cilevel) ///
        id(string) time(string) [ GRAPH GRAPHname(string) ]

    gettoken depvar exog : varlist
    local kx : word count `exog'
    marksample touse
    markout `touse' `depvar' `exog' `id' `time'
    sort `id' `time'

    local names "difference system ddback ddforward full"
    tempname R
    matrix `R' = J(5, 5, .)
    matrix rownames `R' = `names'
    matrix colnames `R' = b se z p moments
    local r 0
    foreach nm of local names {
        local ++r
        tempname b V
        capture mata: _xde_dd_run("`depvar'", "`exog'", "`id'", "`time'", ///
            "`touse'", `lags', `kx', `r', `gmin', `gmax', `two', `wind', "`b'", "`V'")
        local mrc = _rc
        capture confirm scalar __xde_rc
        if _rc local erc 99
        else local erc = __xde_rc
        if `mrc' | `erc' != 0 {
            capture scalar drop __xde_rc __xde_N __xde_Ng __xde_M __xde_J __xde_Jdf
            continue
        }
        local M = __xde_M
        capture scalar drop __xde_N __xde_Ng __xde_M __xde_J __xde_Jdf __xde_rc
        local bb = `b'[1,1]
        local ss = sqrt(`V'[1,1])
        local zz = `bb'/`ss'
        matrix `R'[`r',1] = `bb'
        matrix `R'[`r',2] = `ss'
        matrix `R'[`r',3] = `zz'
        matrix `R'[`r',4] = 2*normal(-abs(`zz'))
        matrix `R'[`r',5] = `M'
    }

    di ""
    di as txt "{hline 74}"
    di as txt "Double-D variant comparison: first-lag (persistence) coefficient"
    di as txt "Dependent variable: " as result "`depvar'" as txt "   AR order: " as result "`lags'"
    di as txt "{hline 74}"
    di as txt %-14s "Variant" %12s "L1 coef" %11s "Std.Err." %9s "z" %10s "p>|z|" %9s "moments"
    di as txt "{hline 74}"
    forvalues i = 1/5 {
        local nm : word `i' of `names'
        local bb = `R'[`i',1]
        if `bb' == . {
            di as txt %-14s "`nm'" as error %12s "(failed/under-id.)"
            continue
        }
        local st ""
        if `R'[`i',4] < .01 local st "***"
        else if `R'[`i',4] < .05 local st "**"
        else if `R'[`i',4] < .10 local st "*"
        di as txt %-14s "`nm'" as result %12.4f `R'[`i',1] %11.4f `R'[`i',2] ///
            %9.2f `R'[`i',3] %10.4f `R'[`i',4] as txt "`st'" _col(66) as result %9.0f `R'[`i',5]
    }
    di as txt "{hline 74}"
    di as txt "Stars: * p<.10  ** p<.05  *** p<.01."
    di as txt "Note: difference/system can be biased under structural breaks; the"
    di as txt "      double-D and full estimators use break-robust moment conditions."
    di as txt "Ref: Chowdhury & Russell (2017), Scott. J. Polit. Econ. 64(4): 373-395."
    di as txt "{hline 74}"

    if "`graph'" != "" {
        _xde_graph_compare `R', depvar(`depvar') level(`level') name(`graphname')
    }

    return matrix compare = `R'
end

*=======================================================================
* Visualization
*=======================================================================
program _xde_graph
    version 16.0
    syntax [, Name(string) ]
    if "`e(cmd)'" != "xtdynestimb" {
        di as error "xtdynestimb graph works only after an xtdynestimb estimation"
        exit 301
    }
    if "`name'" == "" local name "xde_coef"
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    local k = colsof(`b')
    local lvl = e(level)
    local z = invnormal(1 - (100-`lvl')/200)
    local ttl "`e(estimator)'"
    local dv "`e(depvar)'"
    local cnames : colnames `b'

    capture label drop _xdeL
    preserve
    clear
    quietly set obs `k'
    quietly gen double coef = .
    quietly gen double lo = .
    quietly gen double hi = .
    quietly gen idx = _n
    forvalues j = 1/`k' {
        local nm : word `j' of `cnames'
        local bj = `b'[1,`j']
        local sj = sqrt(`V'[`j',`j'])
        quietly replace coef = `bj' in `j'
        quietly replace lo = `bj' - `z'*`sj' in `j'
        quietly replace hi = `bj' + `z'*`sj' in `j'
        label define _xdeL `j' "`nm'", add
    }
    quietly label values idx _xdeL
    twoway (rcap hi lo idx, horizontal lcolor(gs7) lwidth(medthin)) ///
           (scatter idx coef, mcolor(navy) mfcolor(navy) msymbol(O) msize(medium)), ///
        yscale(reverse) ylabel(1(1)`k', valuelabel angle(0) labsize(small) noticks nogrid) ///
        ytitle("") xline(0, lpattern(dash) lcolor(gs9) lwidth(thin)) ///
        xlabel(, grid glcolor(gs15) glwidth(vthin) labsize(small)) ///
        xtitle("Coefficient estimate (`lvl'% confidence interval)", size(small)) ///
        title("`ttl'", size(medsmall) color(black)) ///
        subtitle("Dependent variable: {it:`dv'}", size(small) color(gs5)) ///
        graphregion(color(white) margin(medium)) plotregion(color(white) lcolor(gs10)) ///
        legend(off) name(`name', replace)
    restore
    capture label drop _xdeL
end

program _xde_graph_compare
    version 16.0
    syntax anything(name=mat), depvar(string) level(cilevel) [ Name(string) ]
    if "`name'" == "" local name "xde_compare"
    local z = invnormal(1 - (100-`level')/200)
    capture label drop _xdeC
    preserve
    clear
    quietly set obs 5
    local names "difference system ddback ddforward full"
    quietly gen double coef = .
    quietly gen double lo = .
    quietly gen double hi = .
    quietly gen idx = _n
    forvalues i = 1/5 {
        local nm : word `i' of `names'
        quietly replace coef = `mat'[`i',1] in `i'
        quietly replace lo = `mat'[`i',1] - `z'*`mat'[`i',2] in `i'
        quietly replace hi = `mat'[`i',1] + `z'*`mat'[`i',2] in `i'
        label define _xdeC `i' "`nm'", add
    }
    quietly label values idx _xdeC
    twoway (rcap hi lo idx, lcolor(gs7) lwidth(medthin)) ///
           (scatter coef idx, mcolor(maroon) mfcolor(maroon) msymbol(D) msize(medlarge)), ///
        xlabel(1(1)5, valuelabel angle(30) labsize(small) noticks) ///
        ylabel(, angle(0) labsize(small) grid glcolor(gs15) glwidth(vthin)) ///
        xtitle("") ytitle("First-lag (persistence) coefficient", size(small)) ///
        title("Double-D variant comparison", size(medsmall) color(black)) ///
        subtitle("Dependent variable: {it:`depvar'}   (`level'% CI)", size(small) color(gs5)) ///
        graphregion(color(white) margin(medium)) plotregion(color(white) lcolor(gs10)) ///
        legend(off) name(`name', replace)
    restore
    capture label drop _xdeC
end

* (predict lives in its own file: xtdynestimb_predict.ado)

*=======================================================================
* Mata engine
*=======================================================================
version 16.0
mata:

// ---------------------------------------------------------------------
// Scatter a numeric vector into an N x T panel matrix.
// ---------------------------------------------------------------------
real matrix _xde_tomat(real colvector v, real colvector ridx,
                       real colvector cidx, real scalar N, real scalar T)
{
    real matrix  Y
    real scalar  k, n
    Y = J(N, T, .)
    n = rows(v)
    for (k=1; k<=n; k++) {
        Y[ridx[k], cidx[k]] = v[k]
    }
    return(Y)
}

// First differences over time (column index), N x T (col 1 = missing).
real matrix _xde_diffmat(real matrix Y)
{
    real matrix  D
    real scalar  N, T, i, g
    N = rows(Y); T = cols(Y)
    D = J(N, T, .)
    for (i=1; i<=N; i++) {
        for (g=2; g<=T; g++) {
            if (Y[i,g]!=. & Y[i,g-1]!=.) D[i,g] = Y[i,g] - Y[i,g-1]
        }
    }
    return(D)
}

// Cross-sectional (time) demeaning: subtract each column's mean over the
// non-missing units.  Removes common factors (Sarafidis 2009, eq. 13).
real matrix _xde_timedemean(real matrix Y)
{
    real matrix  D
    real scalar  N, T, g, i, s, c
    N = rows(Y); T = cols(Y)
    D = Y
    for (g=1; g<=T; g++) {
        s = 0; c = 0
        for (i=1; i<=N; i++) {
            if (Y[i,g] != .) {
                s = s + Y[i,g]
                c = c + 1
            }
        }
        if (c > 0) {
            for (i=1; i<=N; i++) {
                if (Y[i,g] != .) D[i,g] = Y[i,g] - s/c
            }
        }
    }
    return(D)
}

// Time-demeaned first differences (AB-LASSO transform: remove gamma_t).
real matrix _xde_diffdemean(real matrix Y)
{
    return(_xde_timedemean(_xde_diffmat(Y)))
}

// Load y into Ymat and covariates into a pointer cell; set N,T by ref.
pointer(real matrix) rowvector _xde_loadX(string scalar yv, string scalar exog,
        string scalar idv, string scalar timev, string scalar tousev,
        real scalar kx, real matrix Ymat, real scalar N, real scalar T)
{
    real colvector id, tt, ids, times, ridx, cidx, yvec
    real scalar    i, g, k, nobs, c
    transmorphic   IA, IB
    string rowvector xnames
    pointer(real matrix) rowvector Xcell

    st_view(id, ., idv,   tousev)
    st_view(tt, ., timev, tousev)
    yvec  = st_data(., yv, tousev)
    ids   = uniqrows(id)
    times = uniqrows(tt)
    N = rows(ids)
    T = rows(times)
    nobs = rows(yvec)

    IA = asarray_create("real"); IB = asarray_create("real")
    for (i=1; i<=N; i++) asarray(IA, ids[i],   i)
    for (g=1; g<=T; g++) asarray(IB, times[g], g)
    ridx = J(nobs,1,0); cidx = J(nobs,1,0)
    for (k=1; k<=nobs; k++) {
        ridx[k] = asarray(IA, id[k])
        cidx[k] = asarray(IB, tt[k])
    }
    Ymat = _xde_tomat(yvec, ridx, cidx, N, T)

    Xcell = J(1, max((kx,1)), NULL)
    if (kx>0) {
        xnames = tokens(exog)
        for (c=1; c<=kx; c++) {
            // &(expression) stores a persistent, distinct copy (no aliasing)
            Xcell[c] = &(_xde_tomat(st_data(., xnames[c], tousev),
                                    ridx, cidx, N, T))
        }
    }
    return(Xcell)
}

// Count usable (non-missing y and covariate) observations.
real scalar _xde_countobs(real matrix Ymat, pointer(real matrix) rowvector Xcell,
                          real scalar kx)
{
    real scalar n, i, g, c, ok
    real matrix Xc
    n = 0
    for (i=1; i<=rows(Ymat); i++) {
        for (g=1; g<=cols(Ymat); g++) {
            if (Ymat[i,g]==.) continue
            ok = 1
            if (kx>0) {
                for (c=1; c<=kx; c++) {
                    Xc = *Xcell[c]
                    if (Xc[i,g]==.) {
                        ok = 0
                        break
                    }
                }
            }
            if (ok) n = n + 1
        }
    }
    return(n)
}

// ---------------------------------------------------------------------
// Build one unit's stacked GMM rows.  Returns the instrument matrix Zi
// (nr x M0), regressors Xi (nr x k), lhs yi (nr x 1), one-step weight Hi
// (nr x nr).  nr = 0 (empty matrices) if the unit contributes no equation.
// Column dictionary (cTag,cG,cIdx) is precomputed in _xde_core.
// ---------------------------------------------------------------------
void _xde_unit(real scalar i, real matrix Ymat,
               pointer(real matrix) rowvector Xcell, real scalar kx,
               real scalar p, real scalar useSys, real scalar M0,
               real colvector cTag, real colvector cG, real colvector cIdx,
               real matrix Zi, real matrix Xi, real matrix Hi,
               real colvector yi)
{
    real scalar  T, g, l, c, e, e2, cc, gg, ok, nr, k, s, f
    real matrix  Xc
    real colvector rg, rt
    T = cols(Ymat)
    k = p + kx

    rg = J(0,1,0); rt = J(0,1,0)
    // difference equations
    for (g=p+2; g<=T; g++) {
        if (Ymat[i,g]==. | Ymat[i,g-1]==.) continue
        ok = 1
        for (l=1; l<=p; l++) {
            if (Ymat[i,g-l]==. | Ymat[i,g-l-1]==.) {
                ok = 0
                break
            }
        }
        if (!ok) continue
        if (kx>0) {
            for (c=1; c<=kx; c++) {
                Xc = *Xcell[c]
                if (Xc[i,g]==. | Xc[i,g-1]==.) {
                    ok = 0
                    break
                }
            }
        }
        if (!ok) continue
        rg = rg \ g; rt = rt \ 1
    }
    // level equations (system)
    if (useSys) {
        for (g=p+2; g<=T; g++) {
            if (Ymat[i,g]==.) continue
            ok = 1
            for (l=1; l<=p; l++) {
                if (Ymat[i,g-l]==.) {
                    ok = 0
                    break
                }
            }
            if (!ok) continue
            if (Ymat[i,g-1]==. | Ymat[i,g-2]==.) continue
            if (kx>0) {
                for (c=1; c<=kx; c++) {
                    Xc = *Xcell[c]
                    if (Xc[i,g]==.) {
                        ok = 0
                        break
                    }
                }
            }
            if (!ok) continue
            rg = rg \ g; rt = rt \ 2
        }
    }

    nr = rows(rg)
    if (nr == 0) {
        Zi = J(0, M0, 0)
        Xi = J(0, k, 0)
        yi = J(0, 1, 0)
        Hi = J(0, 0, 0)
        return
    }

    Zi = J(nr, M0, 0)
    Xi = J(nr, k, 0)
    yi = J(nr, 1, 0)
    for (e=1; e<=nr; e++) {
        gg = rg[e]
        if (rt[e]==1) {
            yi[e] = Ymat[i,gg] - Ymat[i,gg-1]
            for (l=1; l<=p; l++) {
                Xi[e,l] = Ymat[i,gg-l] - Ymat[i,gg-l-1]
            }
            if (kx>0) {
                for (c=1; c<=kx; c++) {
                    Xc = *Xcell[c]
                    Xi[e,p+c] = Xc[i,gg] - Xc[i,gg-1]
                }
            }
            for (cc=1; cc<=M0; cc++) {
                if (cTag[cc]==1 & cG[cc]==gg) {
                    s = cIdx[cc]
                    if (Ymat[i,s]!=.) Zi[e,cc] = Ymat[i,s]
                }
                else if (cTag[cc]==2 & cG[cc]==gg) {
                    s = cIdx[cc]
                    if (Ymat[i,s]!=. & Ymat[i,s-1]!=.) Zi[e,cc] = Ymat[i,s]-Ymat[i,s-1]
                }
                else if (cTag[cc]==3 & cG[cc]==gg) {
                    f = cIdx[cc]
                    if (Ymat[i,f]!=. & Ymat[i,f-1]!=.) Zi[e,cc] = Ymat[i,f]-Ymat[i,f-1]
                }
                else if (cTag[cc]==4) {
                    c = cIdx[cc]
                    Xc = *Xcell[c]
                    if (Xc[i,gg]!=. & Xc[i,gg-1]!=.) Zi[e,cc] = Xc[i,gg]-Xc[i,gg-1]
                }
            }
        }
        else {
            yi[e] = Ymat[i,gg]
            for (l=1; l<=p; l++) {
                Xi[e,l] = Ymat[i,gg-l]
            }
            if (kx>0) {
                for (c=1; c<=kx; c++) {
                    Xc = *Xcell[c]
                    Xi[e,p+c] = Xc[i,gg]
                }
            }
            for (cc=1; cc<=M0; cc++) {
                if (cTag[cc]==5 & cG[cc]==gg) {
                    if (Ymat[i,gg-1]!=. & Ymat[i,gg-2]!=.) Zi[e,cc] = Ymat[i,gg-1]-Ymat[i,gg-2]
                }
                else if (cTag[cc]==6) {
                    c = cIdx[cc]
                    Xc = *Xcell[c]
                    if (Xc[i,gg]!=.) Zi[e,cc] = Xc[i,gg]
                }
            }
        }
    }
    // one-step weight: diff block tridiagonal (2,-1) on consecutive calendar
    // rows; level rows identity; cross-block zero.
    Hi = J(nr, nr, 0)
    for (e=1; e<=nr; e++) {
        if (rt[e]==1) {
            Hi[e,e] = 2
            for (e2=1; e2<=nr; e2++) {
                if (rt[e2]==1) {
                    if (rg[e2]==rg[e]+1 | rg[e2]==rg[e]-1) Hi[e,e2] = -1
                }
            }
        }
        else {
            Hi[e,e] = 1
        }
    }
}

// ---------------------------------------------------------------------
// Core difference / system / double-D GMM (multi-pass; no per-unit cache).
//   vc: 1 diff, 2 system, 3 ddback, 4 ddforward, 5 full.
//   par=1 drops the y-instrument blocks (regressor-only, CSD-robust).
// ---------------------------------------------------------------------
void _xde_core(real matrix Ymat, pointer(real matrix) rowvector Xcell,
               real scalar kx, real scalar p, real scalar vc,
               real scalar gmin, real scalar gmax, real scalar par,
               real scalar twostep, real scalar wind,
               string scalar bname, string scalar Vname)
{
    real scalar  N, T, useL, useDB, useDF, useSys, i, g, s, f, c, lag, M0, k
    real scalar  Nused, M, pp, Jout, dfOut
    real matrix  Zi, Xi, Hi, A, S1, Om, W1, W2, iAW1A, iAW2A, V1r, V2, Vc, D, dOm, Zk
    real colvector yi, bv, keep, th1, th2, u1, gi, g2, Zx, Zu, dcol, cTag, cG, cIdx
    real rowvector bOut
    real matrix  Vout

    N = rows(Ymat)
    T = cols(Ymat)
    k = p + kx

    useL   = (vc==1 | vc==2 | vc==5)
    useDB  = (vc==3 | vc==5)
    useDF  = (vc==4 | vc==5)
    useSys = (vc==2 | vc==5)
    if (par) {
        useL = 0; useDB = 0; useDF = 0
    }

    // ---- instrument-column dictionary ----
    cTag = J(0,1,0); cG = J(0,1,0); cIdx = J(0,1,0)
    for (g=p+2; g<=T; g++) {
        if (useL) {
            for (s=1; s<=g-2; s++) {
                lag = g - s
                if (lag>=gmin & lag<=gmax) {
                    cTag = cTag \ 1; cG = cG \ g; cIdx = cIdx \ s
                }
            }
        }
        if (useDB) {
            for (s=2; s<=g-2; s++) {
                lag = g - s
                if (lag>=gmin & lag<=gmax) {
                    cTag = cTag \ 2; cG = cG \ g; cIdx = cIdx \ s
                }
            }
        }
        if (useDF) {
            for (f=g+2; f<=T; f++) {
                lag = f - g
                if (lag>=gmin & lag<=gmax) {
                    cTag = cTag \ 3; cG = cG \ g; cIdx = cIdx \ f
                }
            }
        }
    }
    if (kx>0) {
        for (c=1; c<=kx; c++) {
            cTag = cTag \ 4; cG = cG \ 0; cIdx = cIdx \ c
        }
    }
    if (useSys) {
        if (!par) {
            for (g=p+2; g<=T; g++) {
                cTag = cTag \ 5; cG = cG \ g; cIdx = cIdx \ 0
            }
        }
        if (kx>0) {
            for (c=1; c<=kx; c++) {
                cTag = cTag \ 6; cG = cG \ 0; cIdx = cIdx \ c
            }
        }
    }
    M0 = rows(cTag)
    if (M0 < k) {
        st_numscalar("__xde_rc", 2)
        return
    }

    // ---- PASS 1: A, bv, S1 ----
    A  = J(M0, k, 0)
    bv = J(M0, 1, 0)
    S1 = J(M0, M0, 0)
    Nused = 0
    for (i=1; i<=N; i++) {
        _xde_unit(i, Ymat, Xcell, kx, p, useSys, M0, cTag, cG, cIdx, Zi, Xi, Hi, yi)
        if (rows(Zi)==0) continue
        Nused = Nused + 1
        A  = A  + quadcross(Zi, Xi)
        bv = bv + quadcross(Zi, yi)
        S1 = S1 + quadcross(Zi, Hi*Zi)
    }
    if (Nused == 0) {
        st_numscalar("__xde_rc", 1)
        return
    }

    keep = select((1::M0), diagonal(S1) :> 1e-12)
    M = rows(keep)
    if (M < k) {
        st_numscalar("__xde_rc", 2)
        return
    }
    A  = A[keep, .]
    bv = bv[keep]
    S1 = S1[keep, keep]
    W1    = invsym(S1)
    iAW1A = invsym(quadcross(A, W1*A))
    th1   = iAW1A * quadcross(A, W1*bv)

    // ---- PASS 2: Om from one-step residuals ----
    Om = J(M, M, 0)
    for (i=1; i<=N; i++) {
        _xde_unit(i, Ymat, Xcell, kx, p, useSys, M0, cTag, cG, cIdx, Zi, Xi, Hi, yi)
        if (rows(Zi)==0) continue
        Zk = Zi[., keep]
        u1 = yi - Xi*th1
        gi = quadcross(Zk, u1)
        Om = Om + gi*gi'
    }
    W2    = invsym(Om)
    iAW2A = invsym(quadcross(A, W2*A))
    th2   = iAW2A * quadcross(A, W2*bv)

    if (twostep) {
        g2 = bv - A*th2
    }
    else {
        g2 = bv - A*th1
    }
    Jout  = (g2' * W2 * g2)
    dfOut = M - k

    if (!twostep) {
        V1r  = iAW1A * quadcross(A, W1*Om*W1*A) * iAW1A
        bOut = th1'
        Vout = V1r
    }
    else if (!wind) {
        bOut = th2'
        Vout = iAW2A
    }
    else {
        // Windmeijer (2005) finite-sample correction
        g2 = bv - A*th2
        D  = J(k, k, 0)
        for (pp=1; pp<=k; pp++) {
            dOm = J(M, M, 0)
            for (i=1; i<=N; i++) {
                _xde_unit(i, Ymat, Xcell, kx, p, useSys, M0, cTag, cG, cIdx, Zi, Xi, Hi, yi)
                if (rows(Zi)==0) continue
                Zk = Zi[., keep]
                u1 = yi - Xi*th1
                Zx = quadcross(Zk, Xi[., pp])
                Zu = quadcross(Zk, u1)
                dOm = dOm + (Zx*Zu' + Zu*Zx')
            }
            dcol = iAW2A * quadcross(A, W2 * dOm * W2 * g2)
            D[., pp] = dcol
        }
        V2  = iAW2A
        V1r = iAW1A * quadcross(A, W1*Om*W1*A) * iAW1A
        Vc  = V2 + D*V2 + (D*V2)' + D*V1r*D'
        bOut = th2'
        Vout = Vc
    }

    Vout = (Vout + Vout') / 2          // enforce symmetry for ereturn post

    real scalar ar1z, ar2z
    real matrix Wuse, Var_ar
    if (twostep) {
        Wuse   = W2
        Var_ar = iAW2A          // analytical efficient avar (AB-test convention)
    }
    else {
        Wuse   = W1
        Var_ar = V1r            // robust one-step avar
    }
    _xde_ar_exact(Ymat, Xcell, kx, p, bOut', A, Wuse, Var_ar, keep, useSys,
                  M0, cTag, cG, cIdx, ar1z, ar2z)

    st_matrix(bname, bOut)
    st_matrix(Vname, Vout)
    st_numscalar("__xde_N",   _xde_countobs(Ymat, Xcell, kx))
    st_numscalar("__xde_Ng",  Nused)
    st_numscalar("__xde_M",   M)
    st_numscalar("__xde_J",   Jout)
    st_numscalar("__xde_Jdf", dfOut)
    st_numscalar("__xde_ar1", ar1z)
    st_numscalar("__xde_ar2", ar2z)
    st_numscalar("__xde_rc",  0)
}

// ---------------------------------------------------------------------
// Arellano-Bond style serial-correlation tests on the first-differenced
// residuals.  w_i^(a) = sum_t Dv_it * Dv_{i,t-a}; with units independent,
// z_a = (sum_i w_i) / sqrt(sum_i w_i^2)  ->d N(0,1) under H0 of no order-a
// serial correlation (cluster-robust over panel units).
// ---------------------------------------------------------------------
void _xde_ar(real matrix Ymat, pointer(real matrix) rowvector Xcell,
             real scalar kx, real scalar p, real colvector theta,
             real scalar ar1z, real scalar ar2z)
{
    real scalar N, T, i, g, l, c, ok, w1, w2, s1n, s1d, s2n, s2d
    real matrix Xc
    real colvector r

    N = rows(Ymat); T = cols(Ymat)
    s1n = 0; s1d = 0; s2n = 0; s2d = 0
    for (i=1; i<=N; i++) {
        r = J(T, 1, .)
        for (g=p+2; g<=T; g++) {
            if (Ymat[i,g]==. | Ymat[i,g-1]==.) continue
            ok = 1
            for (l=1; l<=p; l++) {
                if (Ymat[i,g-l]==. | Ymat[i,g-l-1]==.) {
                    ok = 0
                    break
                }
            }
            if (!ok) continue
            if (kx>0) {
                for (c=1; c<=kx; c++) {
                    Xc = *Xcell[c]
                    if (Xc[i,g]==. | Xc[i,g-1]==.) {
                        ok = 0
                        break
                    }
                }
            }
            if (!ok) continue
            r[g] = Ymat[i,g] - Ymat[i,g-1]
            for (l=1; l<=p; l++) {
                r[g] = r[g] - theta[l]*(Ymat[i,g-l] - Ymat[i,g-l-1])
            }
            if (kx>0) {
                for (c=1; c<=kx; c++) {
                    Xc = *Xcell[c]
                    r[g] = r[g] - theta[p+c]*(Xc[i,g] - Xc[i,g-1])
                }
            }
        }
        w1 = 0; w2 = 0
        for (g=p+3; g<=T; g++) {
            if (r[g]!=. & r[g-1]!=.) w1 = w1 + r[g]*r[g-1]
        }
        for (g=p+4; g<=T; g++) {
            if (r[g]!=. & r[g-2]!=.) w2 = w2 + r[g]*r[g-2]
        }
        s1n = s1n + w1; s1d = s1d + w1*w1
        s2n = s2n + w2; s2d = s2d + w2*w2
    }
    ar1z = .
    ar2z = .
    if (s1d > 0) ar1z = s1n/sqrt(s1d)
    if (s2d > 0) ar2z = s2n/sqrt(s2d)
}

// ---------------------------------------------------------------------
// Exact Arellano-Bond (1991) AR(j) serial-correlation test, including the
// finite-sample correction for the estimation of theta (matches the test
// reported by xtabond/xtabond2/xtdpdgmm).  With e the first-differenced
// residuals and e_L their j-lag,
//   s = sum_i (e_{L,i}'e_i)^2
//       - 2 b' (A'WA)^-1 A'W g  +  b' V(theta) b ,
//   b = sum_i dX_i' e_{L,i},  g = sum_i Z_i'e_i (e_i'e_{L,i}),
//   A = sum_i Z_i'dX_i,  W = GMM weight,  V(theta) = robust var of theta.
//   AR(j) z = (sum_i e_{L,i}'e_i) / sqrt(s)  ->d N(0,1).
// ---------------------------------------------------------------------
void _xde_ar_exact(real matrix Ymat, pointer(real matrix) rowvector Xcell,
                   real scalar kx, real scalar p, real colvector theta,
                   real matrix A, real matrix Wmat, real matrix Vtheta,
                   real colvector keep, real scalar useSys, real scalar M0,
                   real colvector cTag, real colvector cG, real colvector cIdx,
                   real scalar ar1z, real scalar ar2z)
{
    real scalar  N, T, k, M, jj, i, gg, l, c, ok, wi, q, s1, sden, zval
    real scalar  term2, term3
    real matrix  iAWA, Zi, Xi, Hi, Zk, Xc
    real colvector r, yi, vall, mom, b, gM, xr, AWg

    N = rows(Ymat); T = cols(Ymat); k = p + kx; M = rows(keep)
    iAWA = invsym(quadcross(A, Wmat*A))
    ar1z = .
    ar2z = .
    for (jj=1; jj<=2; jj++) {
        q = 0; s1 = 0
        b  = J(k,1,0)
        gM = J(M,1,0)
        for (i=1; i<=N; i++) {
            // reconstruct first-differenced residuals r[gg] by calendar period
            r = J(T,1,.)
            for (gg=p+2; gg<=T; gg++) {
                if (Ymat[i,gg]==. | Ymat[i,gg-1]==.) continue
                ok = 1
                for (l=1; l<=p; l++) {
                    if (Ymat[i,gg-l]==. | Ymat[i,gg-l-1]==.) {
                        ok = 0
                        break
                    }
                }
                if (!ok) continue
                if (kx>0) {
                    for (c=1; c<=kx; c++) {
                        Xc = *Xcell[c]
                        if (Xc[i,gg]==. | Xc[i,gg-1]==.) {
                            ok = 0
                            break
                        }
                    }
                }
                if (!ok) continue
                r[gg] = Ymat[i,gg] - Ymat[i,gg-1]
                for (l=1; l<=p; l++) {
                    r[gg] = r[gg] - theta[l]*(Ymat[i,gg-l]-Ymat[i,gg-l-1])
                }
                if (kx>0) {
                    for (c=1; c<=kx; c++) {
                        Xc = *Xcell[c]
                        r[gg] = r[gg] - theta[p+c]*(Xc[i,gg]-Xc[i,gg-1])
                    }
                }
            }
            // full unit moment Z_i' v_i (uses all rows of this estimator)
            _xde_unit(i, Ymat, Xcell, kx, p, useSys, M0, cTag, cG, cIdx, Zi, Xi, Hi, yi)
            if (rows(Zi) > 0) {
                Zk   = Zi[., keep]
                vall = yi - Xi*theta
                mom  = quadcross(Zk, vall)
            }
            else {
                mom = J(M,1,0)
            }
            // w_i = sum_g r_g r_{g-j} ; b += dX(g)' r_{g-j}
            wi = 0
            for (gg=p+2+jj; gg<=T; gg++) {
                if (r[gg]==. | r[gg-jj]==.) continue
                wi = wi + r[gg]*r[gg-jj]
                xr = J(k,1,0)
                for (l=1; l<=p; l++) {
                    xr[l] = Ymat[i,gg-l] - Ymat[i,gg-l-1]
                }
                if (kx>0) {
                    for (c=1; c<=kx; c++) {
                        Xc = *Xcell[c]
                        xr[p+c] = Xc[i,gg] - Xc[i,gg-1]
                    }
                }
                b = b + xr*r[gg-jj]
            }
            q  = q  + wi
            s1 = s1 + wi*wi
            gM = gM + mom*wi
        }
        AWg   = quadcross(A, Wmat*gM)
        term2 = (b' * iAWA * AWg)
        term3 = (b' * Vtheta * b)
        sden  = s1 - 2*term2 + term3
        if (sden > 0) {
            zval = q/sqrt(sden)
            if (jj==1) ar1z = zval
            else       ar2z = zval
        }
    }
}

// ----------------------- entry points -----------------------
void _xde_dd_run(string scalar yv, string scalar exog, string scalar idv,
                 string scalar timev, string scalar tousev, real scalar p,
                 real scalar kx, real scalar vc, real scalar gmin,
                 real scalar gmax, real scalar twostep, real scalar wind,
                 string scalar bname, string scalar Vname)
{
    real matrix Ymat
    pointer(real matrix) rowvector Xcell
    real scalar N, T
    Xcell = _xde_loadX(yv, exog, idv, timev, tousev, kx, Ymat, N, T)
    _xde_core(Ymat, Xcell, kx, p, vc, gmin, gmax, 0, twostep, wind, bname, Vname)
}

void _xde_csd_run(string scalar yv, string scalar exog, string scalar idv,
                  string scalar timev, string scalar tousev, real scalar p,
                  real scalar kx, real scalar vc, real scalar gmin,
                  real scalar gmax, real scalar par, real scalar dem,
                  real scalar twostep, real scalar wind,
                  string scalar bname, string scalar Vname)
{
    real matrix Ymat, Yd
    pointer(real matrix) rowvector Xcell, Xd
    real scalar N, T, c
    Xcell = _xde_loadX(yv, exog, idv, timev, tousev, kx, Ymat, N, T)
    if (dem) {
        Yd = _xde_timedemean(Ymat)
        Xd = J(1, max((kx,1)), NULL)
        if (kx>0) {
            for (c=1; c<=kx; c++) {
                Xd[c] = &(_xde_timedemean(*Xcell[c]))
            }
        }
        _xde_core(Yd, Xd, kx, p, vc, gmin, gmax, par, twostep, wind, bname, Vname)
    }
    else {
        _xde_core(Ymat, Xcell, kx, p, vc, gmin, gmax, par, twostep, wind, bname, Vname)
    }
}

// ----------------------- LASSO utilities -----------------------
real scalar _xde_soft(real scalar z, real scalar g)
{
    if (z > g)  return(z - g)
    if (z < -g) return(z + g)
    return(0)
}

// coordinate-descent LASSO on standardized X (Xj'Xj/n = 1), centered y.
real colvector _xde_cdlasso(real matrix X, real colvector y, real scalar lam,
                            real scalar maxit, real scalar tol)
{
    real scalar  n, q, it, j, change, bj, rho
    real colvector beta, r
    n = rows(X); q = cols(X)
    beta = J(q, 1, 0)
    r = y
    for (it=1; it<=maxit; it++) {
        change = 0
        for (j=1; j<=q; j++) {
            bj  = beta[j]
            rho = (X[.,j]' * r)/n + bj
            beta[j] = _xde_soft(rho, lam/n)
            if (beta[j] != bj) {
                r = r - X[.,j]*(beta[j]-bj)
                change = change + abs(beta[j]-bj)
            }
        }
        if (change < tol) break
    }
    return(beta)
}

// plug-in penalty level (BCCH, homoskedastic) for standardized design.
//   With the coordinate-descent threshold lam/n and standardized columns,
//   an instrument enters iff its sample correlation with the response
//   exceeds cons*Phi^{-1}(1-gamma/2q)/sqrt(n).
real scalar _xde_lambda(real scalar n, real scalar q, real scalar sd0,
                        real scalar cons, real scalar lamuser)
{
    real scalar gamma
    if (lamuser > 0) return(lamuser)
    gamma = 0.1/ln(max((n, q+1)))
    return(cons*sd0*sqrt(n)*invnormal(1 - gamma/(2*q)))
}

// in-sample LASSO fit of y on candidate matrix C; returns fitted values.
real colvector _xde_lassofit(real matrix C, real colvector y,
                             real scalar lamuser, real scalar cons,
                             real scalar nselout)
{
    real scalar  n, q, j, my, lam, sd0, jbest, best, rj
    real colvector mu, sd, beta, yhat, yc
    real matrix  Cs
    n = rows(C); q = cols(C)
    if (q == 0) return(J(n,1,mean(y)))
    mu = J(q,1,0); sd = J(q,1,1)
    Cs = C
    for (j=1; j<=q; j++) {
        mu[j] = mean(C[.,j])
        sd[j] = sqrt(variance(C[.,j]))
        if (sd[j] <= 1e-10) sd[j] = 1
        Cs[.,j] = (C[.,j] :- mu[j]) :/ sd[j]
    }
    my  = mean(y)
    sd0 = sqrt(variance(y))
    if (sd0 <= 1e-10) sd0 = 1
    yc   = y :- my
    lam  = _xde_lambda(n, q, sd0, cons, lamuser)
    beta = _xde_cdlasso(Cs, yc, lam, 1000, 1e-7)
    if (sum(abs(beta))==0) {            // keep the single strongest instrument
        best = 0; jbest = 0
        for (j=1; j<=q; j++) {
            rj = abs((Cs[.,j]' * yc)/n)
            if (rj > best) {
                best = rj; jbest = j
            }
        }
        if (jbest > 0) beta[jbest] = (Cs[.,jbest]' * yc)/n
    }
    nselout = sum(beta :!= 0)
    yhat = J(n,1,my)
    for (j=1; j<=q; j++) {
        if (beta[j] != 0) yhat = yhat + Cs[.,j]*beta[j]
    }
    return(yhat)
}

// out-of-sample LASSO fit: train on (Ctr,ytr), predict on Cte.
real colvector _xde_lassofit_oos(real matrix Ctr, real colvector ytr,
                                 real matrix Cte, real scalar lamuser,
                                 real scalar cons, real scalar nselout)
{
    real scalar  n, q, j, my, lam, sd0, jbest, best, rj
    real colvector mu, sd, beta, yhat, yc
    real matrix  Cs, Ces
    n = rows(Ctr); q = cols(Ctr)
    if (q == 0) return(J(rows(Cte),1,mean(ytr)))
    mu = J(q,1,0); sd = J(q,1,1)
    Cs = Ctr; Ces = Cte
    for (j=1; j<=q; j++) {
        mu[j] = mean(Ctr[.,j])
        sd[j] = sqrt(variance(Ctr[.,j]))
        if (sd[j] <= 1e-10) sd[j] = 1
        Cs[.,j]  = (Ctr[.,j] :- mu[j]) :/ sd[j]
        Ces[.,j] = (Cte[.,j] :- mu[j]) :/ sd[j]
    }
    my  = mean(ytr)
    sd0 = sqrt(variance(ytr))
    if (sd0 <= 1e-10) sd0 = 1
    yc   = ytr :- my
    lam  = _xde_lambda(n, q, sd0, cons, lamuser)
    beta = _xde_cdlasso(Cs, yc, lam, 1000, 1e-7)
    if (sum(abs(beta))==0) {
        best = 0; jbest = 0
        for (j=1; j<=q; j++) {
            rj = abs((Cs[.,j]' * yc)/n)
            if (rj > best) {
                best = rj; jbest = j
            }
        }
        if (jbest > 0) beta[jbest] = (Cs[.,jbest]' * yc)/n
    }
    nselout = sum(beta :!= 0)
    yhat = J(rows(Cte),1,my)
    for (j=1; j<=q; j++) {
        if (beta[j] != 0) yhat = yhat + Ces[.,j]*beta[j]
    }
    return(yhat)
}

// count non-zero entries among the LASSO-fitted (endogenous) columns 1..p.
real scalar _xde_countnz(real matrix What, real scalar p)
{
    real scalar j, c, n
    n = 0
    for (j=1; j<=rows(What); j++) {
        for (c=1; c<=p; c++) {
            if (What[j,c] != 0) n = n + 1
        }
    }
    return(n)
}

// random fold assignment 1..kfold over N units.
real colvector _xde_makefolds(real scalar N, real scalar kfold)
{
    real colvector u, ord, fold
    real scalar i
    u    = runiform(N,1)
    ord  = order(u, 1)
    fold = J(N,1,0)
    for (i=1; i<=N; i++) fold[ord[i]] = mod(i-1, kfold) + 1
    return(fold)
}

// ---------------------------------------------------------------------
// Assemble period-t AB-LASSO data and optimal instruments.
//   Endogenous regressors: Dy_{t-1..t-p} (time-demeaned differences).
//   Exogenous regressors:  Dx_t (their own instrument).
//   Candidate instruments: y levels at 1..t-2.
//   Returns idxv (valid units), Whatsub, DXsub, DYsub, nsel.
// ---------------------------------------------------------------------
void _xde_abl_period(real matrix Ymat, real matrix DYd,
        pointer(real matrix) rowvector DXcell, real scalar kx, real scalar p,
        real scalar N, real scalar t, real scalar cf, real scalar kfold,
        real colvector splitid, real scalar lamuser, real scalar cons,
        real colvector idxv, real matrix Whatsub, real matrix DXsub,
        real colvector DYsub, real scalar nsel)
{
    real scalar  k, qy, i, l, c, s, ok, fold, col, nselc, nselacc, ncalls
    real matrix  Cfull, DXfull, DXc, Csub, foldcol
    real colvector validrow, DYfull, foldsub, tr, te

    k  = p + kx
    qy = t - 2
    validrow = J(N,1,0)
    Cfull    = J(N, qy, .)
    DXfull   = J(N, k, .)
    DYfull   = J(N, 1, .)

    for (i=1; i<=N; i++) {
        ok = 1
        if (DYd[i,t]==.) ok = 0
        if (ok) {
            for (l=1; l<=p; l++) {
                if (t-l < 2) {
                    ok = 0
                    break
                }
                if (DYd[i,t-l]==.) {
                    ok = 0
                    break
                }
            }
        }
        if (ok & kx>0) {
            for (c=1; c<=kx; c++) {
                DXc = *DXcell[c]
                if (DXc[i,t]==.) {
                    ok = 0
                    break
                }
            }
        }
        if (ok) {
            for (s=1; s<=qy; s++) {
                if (Ymat[i,s]==.) {
                    ok = 0
                    break
                }
                Cfull[i,s] = Ymat[i,s]
            }
        }
        if (!ok) continue
        validrow[i] = 1
        DYfull[i] = DYd[i,t]
        for (l=1; l<=p; l++) DXfull[i,l] = DYd[i,t-l]
        if (kx>0) {
            for (c=1; c<=kx; c++) {
                DXc = *DXcell[c]
                DXfull[i,p+c] = DXc[i,t]
            }
        }
    }

    idxv = selectindex(validrow)
    if (rows(idxv) <= 2) {
        Whatsub = J(0,k,0); DXsub = J(0,k,0); DYsub = J(0,1,0); nsel = 0
        return
    }
    Csub  = Cfull[idxv, .]
    DXsub = DXfull[idxv, .]
    DYsub = DYfull[idxv]
    Whatsub = J(rows(idxv), k, 0)
    nselacc = 0; ncalls = 0; nselc = 0

    if (cf) {
        foldsub = splitid[idxv]
        for (fold=1; fold<=kfold; fold++) {
            tr = selectindex(foldsub :!= fold)
            te = selectindex(foldsub :== fold)
            if (rows(te)==0 | rows(tr)<=2) continue
            for (col=1; col<=p; col++) {
                Whatsub[te, col] = _xde_lassofit_oos(Csub[tr,.], DXsub[tr,col],
                                                     Csub[te,.], lamuser, cons, nselc)
                nselacc = nselacc + nselc; ncalls = ncalls + 1
            }
        }
    }
    else {
        for (col=1; col<=p; col++) {
            Whatsub[., col] = _xde_lassofit(Csub, DXsub[.,col], lamuser, cons, nselc)
            nselacc = nselacc + nselc; ncalls = ncalls + 1
        }
    }
    if (kx>0) {
        for (col=p+1; col<=k; col++) Whatsub[., col] = DXsub[., col]
    }
    if (ncalls > 0) {
        nsel = nselacc/ncalls
    }
    else {
        nsel = 0
    }
}

// one AB-LASSO pass -> bRun (1 x k), VRun (k x k), avg # selected.
void _xde_abl_one(real matrix Ymat, real matrix DYd,
                  pointer(real matrix) rowvector DXcell, real scalar kx,
                  real scalar p, real scalar N, real scalar T, real scalar cf,
                  real scalar kfold, real colvector splitid, real scalar lamuser,
                  real scalar cons, real rowvector bRun, real matrix VRun,
                  real scalar nselRun)
{
    real scalar  k, t, rr, i, nper, nseltot, nselp
    real matrix  Amat, Gmat, iA, Whatsub, DXsub, Meat
    real colvector bvec, theta, idxv, DYsub, u

    k = p + kx
    Amat = J(k,k,0)
    bvec = J(k,1,0)
    Gmat = J(N,k,0)
    nper = 0; nseltot = 0

    // PASS 1: A, b
    for (t=p+2; t<=T; t++) {
        if (t-2 < 1) continue
        _xde_abl_period(Ymat, DYd, DXcell, kx, p, N, t, cf, kfold, splitid,
                        lamuser, cons, idxv, Whatsub, DXsub, DYsub, nselp)
        if (rows(idxv) <= 2) continue
        Amat = Amat + quadcross(Whatsub, DXsub)
        bvec = bvec + quadcross(Whatsub, DYsub)
        nseltot = nseltot + nselp
        nper = nper + 1
    }
    if (nper == 0) {
        bRun = J(1,k,.)
        VRun = J(k,k,.)
        nselRun = .
        return
    }
    iA = invsym(Amat)
    theta = iA * bvec

    // PASS 2: cluster moments for VCE
    for (t=p+2; t<=T; t++) {
        if (t-2 < 1) continue
        _xde_abl_period(Ymat, DYd, DXcell, kx, p, N, t, cf, kfold, splitid,
                        lamuser, cons, idxv, Whatsub, DXsub, DYsub, nselp)
        if (rows(idxv) <= 2) continue
        u = DYsub - DXsub*theta
        for (rr=1; rr<=rows(idxv); rr++) {
            i = idxv[rr]
            Gmat[i,.] = Gmat[i,.] + Whatsub[rr,.]*u[rr]
        }
    }
    Meat = quadcross(Gmat, Gmat)
    VRun = iA * Meat * iA'
    bRun = theta'
    nselRun = nseltot/nper
}

// ---------------------------------------------------------------------
// AB-LASSO driver with optional cross-fitting and multiple sample splits.
//   Aggregates across splits by averaging the point estimates and adding
//   the between-split variance to the average within-split VCE (DML rule).
// ---------------------------------------------------------------------
void _xde_abl_run(string scalar yv, string scalar exog, string scalar idv,
                  string scalar timev, string scalar tousev, real scalar p,
                  real scalar kx, real scalar cf, real scalar kfold,
                  real scalar nsplits, real scalar lamuser, real scalar cons,
                  string scalar bname, string scalar Vname)
{
    real matrix  Ymat, DYd
    pointer(real matrix) rowvector Xcell, DXcell
    real scalar  N, T, c, k, rep, cnt, nseltot
    real colvector bsum, theta
    real matrix  bbsum, Vsum, between, Vtot, VRun
    real rowvector bRun
    real scalar  nselRun
    real colvector splitid

    Xcell = _xde_loadX(yv, exog, idv, timev, tousev, kx, Ymat, N, T)
    k = p + kx

    DYd = _xde_diffdemean(Ymat)
    DXcell = J(1, max((kx,1)), NULL)
    if (kx>0) {
        for (c=1; c<=kx; c++) {
            DXcell[c] = &(_xde_diffdemean(*Xcell[c]))
        }
    }

    bsum  = J(k,1,0)
    bbsum = J(k,k,0)
    Vsum  = J(k,k,0)
    cnt   = 0
    nseltot = 0
    for (rep=1; rep<=nsplits; rep++) {
        if (cf) {
            splitid = _xde_makefolds(N, kfold)
        }
        else {
            splitid = J(N,1,1)
        }
        _xde_abl_one(Ymat, DYd, DXcell, kx, p, N, T, cf, kfold, splitid,
                     lamuser, cons, bRun, VRun, nselRun)
        if (bRun[1] != .) {
            theta = bRun'
            bsum  = bsum + theta
            bbsum = bbsum + theta*theta'
            Vsum  = Vsum + VRun
            nseltot = nseltot + nselRun
            cnt = cnt + 1
        }
    }
    if (cnt == 0) {
        st_numscalar("__xde_rc", 3)
        return
    }
    theta = bsum/cnt
    if (cnt > 1) {
        between = bbsum/cnt - theta*theta'
    }
    else {
        between = J(k,k,0)
    }
    Vtot = Vsum/cnt + between
    Vtot = (Vtot + Vtot') / 2          // enforce symmetry for ereturn post

    st_matrix(bname, theta')
    st_matrix(Vname, Vtot)
    st_numscalar("__xde_N",    _xde_countobs(Ymat, Xcell, kx))
    st_numscalar("__xde_Ng",   N)
    st_numscalar("__xde_Tmax", T)
    st_numscalar("__xde_navg", nseltot/cnt)
    st_numscalar("__xde_lam",  lamuser)
    st_numscalar("__xde_rc",   0)
}

// =====================================================================
// DAB-SS: debiased Arellano-Bond via split-panel (cross-section) jackknife
//   (Chen, Chernozhukov & Fernandez-Val 2019; the 4th column of the
//   AB-LASSO paper's Table 5.1).  theta_DAB = 2*theta_full - mean of the
//   two half-sample AB estimates, removing the O(T/N) many-moment bias.
// =====================================================================

// lean two-step difference (Arellano-Bond) GMM fit; by-ref outputs.
void _xde_diffgmm(real matrix Ymat, pointer(real matrix) rowvector Xcell,
                  real scalar kx, real scalar p, real scalar gmin, real scalar gmax,
                  real scalar twostep, real scalar wind,
                  real rowvector bOut, real matrix Vout, real scalar okOut)
{
    real scalar  N, T, g, s, lag, M0, k, i, M, Nused, pp
    real colvector cTag, cG, cIdx, yi, bv, keep, th1, th2, u1, gi, g2, Zx, Zu, dcol
    real matrix  Zi, Xi, Hi, A, S1, Om, W1, W2, iAW1A, iAW2A, V1r, V2, Vc, D, dOm, Zk

    okOut = 1
    N = rows(Ymat); T = cols(Ymat); k = p + kx
    cTag = J(0,1,0); cG = J(0,1,0); cIdx = J(0,1,0)
    for (g=p+2; g<=T; g++) {
        for (s=1; s<=g-2; s++) {
            lag = g - s
            if (lag>=gmin & lag<=gmax) {
                cTag = cTag \ 1; cG = cG \ g; cIdx = cIdx \ s
            }
        }
    }
    if (kx>0) {
        for (i=1; i<=kx; i++) {
            cTag = cTag \ 4; cG = cG \ 0; cIdx = cIdx \ i
        }
    }
    M0 = rows(cTag)
    if (M0 < k) {
        okOut = 0
        return
    }
    A = J(M0,k,0); bv = J(M0,1,0); S1 = J(M0,M0,0); Nused = 0
    for (i=1; i<=N; i++) {
        _xde_unit(i, Ymat, Xcell, kx, p, 0, M0, cTag, cG, cIdx, Zi, Xi, Hi, yi)
        if (rows(Zi)==0) continue
        Nused = Nused + 1
        A  = A  + quadcross(Zi, Xi)
        bv = bv + quadcross(Zi, yi)
        S1 = S1 + quadcross(Zi, Hi*Zi)
    }
    if (Nused == 0) {
        okOut = 0
        return
    }
    keep = select((1::M0), diagonal(S1) :> 1e-12)
    M = rows(keep)
    if (M < k) {
        okOut = 0
        return
    }
    A = A[keep,.]; bv = bv[keep]; S1 = S1[keep,keep]
    W1 = invsym(S1)
    iAW1A = invsym(quadcross(A, W1*A))
    th1 = iAW1A * quadcross(A, W1*bv)
    Om = J(M,M,0)
    for (i=1; i<=N; i++) {
        _xde_unit(i, Ymat, Xcell, kx, p, 0, M0, cTag, cG, cIdx, Zi, Xi, Hi, yi)
        if (rows(Zi)==0) continue
        Zk = Zi[., keep]
        u1 = yi - Xi*th1
        gi = quadcross(Zk, u1)
        Om = Om + gi*gi'
    }
    W2 = invsym(Om)
    iAW2A = invsym(quadcross(A, W2*A))
    th2 = iAW2A * quadcross(A, W2*bv)
    if (!twostep) {
        V1r = iAW1A * quadcross(A, W1*Om*W1*A) * iAW1A
        bOut = th1'
        Vout = V1r
    }
    else if (!wind) {
        bOut = th2'
        Vout = iAW2A
    }
    else {
        g2 = bv - A*th2
        D = J(k,k,0)
        for (pp=1; pp<=k; pp++) {
            dOm = J(M,M,0)
            for (i=1; i<=N; i++) {
                _xde_unit(i, Ymat, Xcell, kx, p, 0, M0, cTag, cG, cIdx, Zi, Xi, Hi, yi)
                if (rows(Zi)==0) continue
                Zk = Zi[., keep]
                u1 = yi - Xi*th1
                Zx = quadcross(Zk, Xi[., pp])
                Zu = quadcross(Zk, u1)
                dOm = dOm + (Zx*Zu' + Zu*Zx')
            }
            dcol = iAW2A * quadcross(A, W2 * dOm * W2 * g2)
            D[., pp] = dcol
        }
        V2 = iAW2A
        V1r = iAW1A * quadcross(A, W1*Om*W1*A) * iAW1A
        Vc = V2 + D*V2 + (D*V2)' + D*V1r*D'
        bOut = th2'
        Vout = Vc
    }
    Vout = (Vout + Vout') / 2
}

// subset a covariate cell to the given rows (distinct persistent copies).
pointer(real matrix) rowvector _xde_subX(pointer(real matrix) rowvector Xcell,
        real scalar kx, real colvector rows)
{
    pointer(real matrix) rowvector XS
    real scalar c
    XS = J(1, max((kx,1)), NULL)
    if (kx>0) {
        for (c=1; c<=kx; c++) {
            XS[c] = &((*Xcell[c])[rows, .])
        }
    }
    return(XS)
}

void _xde_dab_run(string scalar yv, string scalar exog, string scalar idv,
                  string scalar timev, string scalar tousev, real scalar p,
                  real scalar kx, real scalar gmin, real scalar gmax,
                  real scalar twostep, real scalar wind,
                  string scalar bname, string scalar Vname)
{
    real matrix  Ymat, YA, YB, Vf, Va, Vb
    pointer(real matrix) rowvector Xcell, XA, XB
    real scalar  N, T, k, nh, okf, okA, okB, ar1z, ar2z
    real rowvector bf, ba, bb, bdab
    real colvector rowsA, rowsB

    Xcell = _xde_loadX(yv, exog, idv, timev, tousev, kx, Ymat, N, T)
    k = p + kx
    nh = floor(N/2)
    if (nh < 2 | N-nh < 2) {
        st_numscalar("__xde_rc", 1)
        return
    }
    rowsA = (1::nh)
    rowsB = ((nh+1)::N)
    YA = Ymat[rowsA, .]
    YB = Ymat[rowsB, .]
    XA = _xde_subX(Xcell, kx, rowsA)
    XB = _xde_subX(Xcell, kx, rowsB)

    _xde_diffgmm(Ymat, Xcell, kx, p, gmin, gmax, twostep, wind, bf, Vf, okf)
    _xde_diffgmm(YA, XA, kx, p, gmin, gmax, twostep, wind, ba, Va, okA)
    _xde_diffgmm(YB, XB, kx, p, gmin, gmax, twostep, wind, bb, Vb, okB)
    if (!okf | !okA | !okB) {
        st_numscalar("__xde_rc", 2)
        return
    }
    bdab = 2*bf - (ba + bb)/2

    _xde_ar(Ymat, Xcell, kx, p, bdab', ar1z, ar2z)

    st_matrix(bname, bdab)
    st_matrix(Vname, Vf)
    st_numscalar("__xde_N",   _xde_countobs(Ymat, Xcell, kx))
    st_numscalar("__xde_Ng",  N)
    st_numscalar("__xde_ar1", ar1z)
    st_numscalar("__xde_ar2", ar2z)
    st_numscalar("__xde_rc",  0)
}

// =====================================================================
// Bai & Perron (1998) multiple mean-shift break detection on a single
// time series (reproduces the "Table A1" regime step of Chowdhury &
// Russell 2017).  Dynamic-programming partition; number of breaks by BIC.
// =====================================================================
void _xde_baiperron(real colvector y, real scalar Mmax, real scalar h,
                    real matrix REG, real scalar selm)
{
    real scalar  T, m, j, l, t, big, sm, nreg, r, a2, b2
    real colvector PS, PS2, bic, bp
    real matrix  C, POS

    big = 1e300
    T = rows(y)
    PS = J(T+1,1,0); PS2 = J(T+1,1,0)
    for (t=1; t<=T; t++) {
        PS[t+1]  = PS[t]  + y[t]
        PS2[t+1] = PS2[t] + y[t]*y[t]
    }

    C   = J(Mmax+1, T, big)
    POS = J(Mmax+1, T, 0)
    for (j=h; j<=T; j++) {
        C[1,j] = (PS2[j+1]-PS2[1]) - (PS[j+1]-PS[1])^2/j
    }
    for (m=1; m<=Mmax; m++) {
        for (j=(m+1)*h; j<=T; j++) {
            for (l=m*h; l<=j-h; l++) {
                if (C[m,l] < big) {
                    sm = C[m,l] + ((PS2[j+1]-PS2[l+1]) - (PS[j+1]-PS[l+1])^2/(j-l))
                    if (sm < C[m+1,j]) {
                        C[m+1,j] = sm
                        POS[m+1,j] = l
                    }
                }
            }
        }
    }

    bic = J(Mmax+1,1,big)
    for (m=0; m<=Mmax; m++) {
        if (C[m+1,T] < big & C[m+1,T] > 1e-12) {
            bic[m+1] = T*ln(C[m+1,T]/T) + (2*m+1)*ln(T)
        }
    }
    selm = 0
    for (m=1; m<=Mmax; m++) {
        if (bic[m+1] < bic[selm+1]) selm = m
    }

    bp = J(selm,1,0)
    j = T
    for (m=selm; m>=1; m--) {
        l = POS[m+1, j]
        bp[m] = l
        j = l
    }

    nreg = selm + 1
    REG = J(nreg, 3, 0)
    a2 = 1
    for (r=1; r<=nreg; r++) {
        if (r < nreg) b2 = bp[r]
        else          b2 = T
        REG[r,1] = a2
        REG[r,2] = b2
        REG[r,3] = (PS[b2+1]-PS[a2])/(b2-a2+1)
        a2 = b2 + 1
    }
}

// aggregate the dependent variable cross-sectionally (mean per period),
// detect mean breaks, and post a regime table mapped to the time values.
void _xde_breaks_run(string scalar yv, string scalar timev, string scalar tousev,
                     real scalar Mmax, real scalar h, string scalar resname)
{
    real colvector y, tt, times, s, cnt
    real scalar    T, k, nobs, g, selm, nreg, r, hh
    real matrix    REG, OUT
    transmorphic   IB

    y  = st_data(., yv, tousev)
    tt = st_data(., timev, tousev)
    times = uniqrows(tt)
    T = rows(times)
    nobs = rows(y)

    IB = asarray_create("real")
    for (g=1; g<=T; g++) asarray(IB, times[g], g)
    s   = J(T,1,0)
    cnt = J(T,1,0)
    for (k=1; k<=nobs; k++) {
        g = asarray(IB, tt[k])
        if (y[k] != .) {
            s[g]   = s[g] + y[k]
            cnt[g] = cnt[g] + 1
        }
    }
    for (g=1; g<=T; g++) {
        if (cnt[g] > 0) s[g] = s[g]/cnt[g]
    }

    hh = h
    if (hh < 1) {
        hh = floor(0.15*T)
        if (hh < 2) hh = 2
    }
    if (Mmax > floor(T/hh) - 1) Mmax = floor(T/hh) - 1
    if (Mmax < 0) Mmax = 0

    _xde_baiperron(s, Mmax, hh, REG, selm)
    nreg = rows(REG)
    OUT = J(nreg, 5, 0)
    for (r=1; r<=nreg; r++) {
        OUT[r,1] = r
        OUT[r,2] = times[REG[r,1]]
        OUT[r,3] = times[REG[r,2]]
        OUT[r,4] = REG[r,2] - REG[r,1] + 1
        OUT[r,5] = REG[r,3]
    }
    st_matrix(resname, OUT)
    st_numscalar("__xde_nbreaks", selm)
    st_numscalar("__xde_nreg", nreg)
    st_numscalar("__xde_minlen", hh)
}

end
