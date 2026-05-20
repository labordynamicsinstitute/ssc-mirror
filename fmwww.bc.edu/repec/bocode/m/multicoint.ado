*! multicoint v1.0.0  18may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Multicointegration estimation & testing for I(1)/I(2) time-series
*! ---------------------------------------------------------------------------
*! References (key):
*!   Granger & Lee (1989, JAE; 1990, Adv. Econometrics)
*!   Engsted, Gonzalo & Haldrup (1997, Econ. Letters)
*!   Engsted & Haldrup (1999, OBES)
*!   Engsted & Johansen (1997, EUI WP)
*!   Haldrup (1994, J. Econometrics)
*!   Hwang & Sun (2018, J. Econometrics)
*!   Sun & Yang (2025, 2026) - TAOLS
*!
*! Estimators :  OLS  DOLS  FM-OLS  IM-OLS  CCR  TAOLS
*! Tests      :  gl   egh  taols  all  none
*!
*! Multicointegration regression actually estimated:
*!     Y_t = a + d1*t + d2*t^2 + b'*X_t + g'*x_t + u_t
*! with    Y_t = sum_{s<=t} y_s     (I(2)),
*!         X_t = sum_{s<=t} x_s     (I(2)),
*!         x_t                      (I(1) flow regressors, supplied by user),
*!         u_t                      (I(0) under multicointegration).
*! ---------------------------------------------------------------------------

program define multicoint, eclass sortpreserve
    version 14.0

    if replay() {
        if "`e(cmd)'" != "multicoint" {
            di as err "last estimation results are not from {bf:multicoint}"
            exit 301
        }
        _mc_display
        exit
    }

    syntax varlist(min=2 numeric ts) [if] [in] [,    ///
        TEST(string)            ///
        ESTimator(string)       ///
        TRend(string)           ///
        LAGS(integer 0)         ///
        AUTOlag(string)         ///
        MAXLag(integer 8)       ///
        LEADS(integer 2)        ///
        DLAGS(integer 2)        ///
        KERnel(string)          ///
        BWidth(real 0)          ///
        K(integer 12)           ///
        Level(cilevel)          ///
        GRaph                   ///
        GRSave(string)          ///
        NOTABle                 ///
        NOConstant              ///
        ]

    marksample touse
    qui tsset, noquery
    local tvar `r(timevar)'

    if "`estimator'" == "" local estimator "ols"
    if "`test'"      == "" local test      "egh"
    if "`trend'"     == "" local trend     "ct"
    if "`kernel'"    == "" local kernel    "bartlett"
    if "`autolag'"   == "" local autolag   "fixed"

    local estimator = lower("`estimator'")
    local test      = lower("`test'")
    local trend     = lower("`trend'")
    local kernel    = lower("`kernel'")
    local autolag   = lower("`autolag'")

    if !inlist("`estimator'","ols","dols","fmols","imols","ccr","taols") {
        di as err "estimator() must be one of: ols dols fmols imols ccr taols"
        exit 198
    }
    if !inlist("`test'","gl","egh","taols","all","none") {
        di as err "test() must be one of: gl egh taols all none"
        exit 198
    }
    if !inlist("`trend'","none","c","ct","ctt") {
        di as err "trend() must be one of: none c ct ctt"
        exit 198
    }
    if !inlist("`kernel'","bartlett","parzen","qs") {
        di as err "kernel() must be one of: bartlett parzen qs"
        exit 198
    }
    if !inlist("`autolag'","aic","bic","hqic","fixed") {
        di as err "autolag() must be one of: AIC BIC HQIC fixed"
        exit 198
    }

    gettoken yvar xvars : varlist
    local nx : word count `xvars'

    qui count if `touse'
    local Nuse = r(N)
    if `Nuse' < 30 {
        di as err "need at least 30 usable observations (got `Nuse')"
        exit 2001
    }

    * --------------------------------------------------------------
    * Build cumulated I(2) series + time trends (sample-sorted)
    * --------------------------------------------------------------
    qui sort `tvar'
    tempvar Ycum tt tt2
    qui gen double `Ycum' = sum(`yvar') if `touse'

    local Xcum
    local i = 0
    foreach v of local xvars {
        local ++i
        tempvar Xc`i'
        qui gen double `Xc`i'' = sum(`v') if `touse'
        local Xcum `Xcum' `Xc`i''
    }
    qui gen long   `tt'  = sum(`touse') if `touse'
    qui gen double `tt2' = `tt'^2 if `touse'

    local eqtrend = 0
    if "`trend'" == "ct"  local eqtrend = 1
    if "`trend'" == "ctt" local eqtrend = 2

    * All regressors in the multicoint regression: cumulated I(2) + flow I(1)
    local Xall  `Xcum' `xvars'

    * ---------------------------------------------------------------
    * Dispatch to estimator and obtain b, V, residuals
    * ---------------------------------------------------------------
    tempname Bhat Vhat
    tempvar uhat

    if "`estimator'" == "ols" {
        _mc_est_ols `Ycum' `Xall' if `touse',                          ///
            trend(`trend') `noconstant' resid(`uhat')
        mat `Bhat' = r(b)
        mat `Vhat' = r(V)
        local rss = r(rss)
        local r2  = r(r2)
        local Nrun = r(N)
        local lrse = .
    }
    else if inlist("`estimator'","fmols","dols","ccr") {
        cap which cointreg
        if _rc {
            di as err "{bf:`estimator'} requires the {bf:cointreg} package (Wang 2011)."
            di as err "Install with:  ssc install cointreg"
            exit 199
        }
        local opts
        if "`estimator'" == "dols" {
            local opts dlead(`leads') dlag(`dlags') dic(aic)
        }
        if inlist("`estimator'","fmols","ccr") {
            local opts kernel(`kernel') bmeth(andrews)
            if `bwidth' > 0 local opts `opts' bwidth(`bwidth')
        }
        qui cointreg `Ycum' `Xall' if `touse',                          ///
            est(`estimator') eqtrend(`eqtrend') `noconstant' `opts'
        mat `Bhat' = e(b)
        mat `Vhat' = e(V)
        local rss   = e(rss)
        local r2    = e(r2)
        local lrse  = e(lrse)
        local Nrun  = e(N)
        * recompute residuals via OLS at the cointreg betas
        _mc_resid_from_b `Ycum' `Xall' if `touse',                      ///
            bmat(`Bhat') trend(`trend') `noconstant' resid(`uhat')
    }
    else if "`estimator'" == "imols" {
        _mc_est_imols `Ycum' `Xall' if `touse',                         ///
            trend(`trend') `noconstant' resid(`uhat')
        mat `Bhat' = r(b)
        mat `Vhat' = r(V)
        local rss   = r(rss)
        local r2    = r(r2)
        local Nrun  = r(N)
        local lrse = .
    }
    else if "`estimator'" == "taols" {
        _mc_est_taols `Ycum' `Xall' if `touse',                         ///
            trend(`trend') k(`k') nx(`nx') resid(`uhat')
        mat `Bhat' = r(b)
        mat `Vhat' = r(V)
        local rss   = r(rss)
        local r2    = r(r2)
        local Nrun  = r(N)
        local lrse = .
    }

    * --------- assign nice colnames ---------
    local cnames
    forvalues i=1/`nx' {
        local xi : word `i' of `xvars'
        local cnames `cnames' `xi'_cum
    }
    local cnames `cnames' `xvars'
    if "`trend'" != "none" {
        if "`noconstant'" == "" local cnames `cnames' _cons
        if "`trend'" == "ct" | "`trend'" == "ctt" local cnames `cnames' _trend
        if "`trend'" == "ctt"                     local cnames `cnames' _trend2
    }
    cap mat colnames `Bhat' = `cnames'
    cap mat colnames `Vhat' = `cnames'
    cap mat rownames `Vhat' = `cnames'

    * Persist residual + cumulated series for downstream use/graphs
    cap drop _mc_uhat _mc_Ycum
    qui gen double _mc_uhat = `uhat' if `touse'
    label var _mc_uhat "Multicoint regression residual"
    qui gen double _mc_Ycum = `Ycum' if `touse'
    label var _mc_Ycum "Cumulated `yvar' (sum)"
    local Xcumperm
    forvalues i=1/`nx' {
        cap drop _mc_Xcum`i'
        local v : word `i' of `xvars'
        local xc: word `i' of `Xcum'
        qui gen double _mc_Xcum`i' = `xc' if `touse'
        label var _mc_Xcum`i' "Cumulated `v' (sum)"
        local Xcumperm `Xcumperm' _mc_Xcum`i'
    }

    * ---------------------------------------------------------------
    * Run tests
    * ---------------------------------------------------------------
    local has_gl = 0
    local has_egh = 0
    local has_taols = 0

    if inlist("`test'","gl","all") {
        _mc_test_gl `yvar' `xvars' if `touse',                          ///
            trend(`trend') lags(`lags') autolag(`autolag') maxlag(`maxlag')
        scalar mc_gl_stat = r(stat)
        scalar mc_gl_lags = r(lags)
        scalar mc_gl_p    = r(pval)
        scalar mc_gl_cv05 = r(cv05)
        local has_gl = 1
    }
    if inlist("`test'","egh","all") {
        _mc_test_egh `uhat' if `touse',                                  ///
            trend(`trend') lags(`lags') autolag(`autolag') maxlag(`maxlag') ///
            m1(`nx') m2(`nx')
        scalar mc_egh_stat = r(stat)
        scalar mc_egh_lags = r(lags)
        scalar mc_egh_cv01  = r(cv01)
        scalar mc_egh_cv025 = r(cv025)
        scalar mc_egh_cv05  = r(cv05)
        scalar mc_egh_cv10  = r(cv10)
        local has_egh = 1
    }
    if inlist("`test'","taols","all") {
        _mc_test_taols `Ycum' `Xall' if `touse',                        ///
            trend(`trend') k(`k') nx(`nx')
        scalar mc_taols_Fm   = r(Fm)
        scalar mc_taols_Fm_p = r(Fm_p)
        scalar mc_taols_Fc   = r(Fc)
        scalar mc_taols_Fc_p = r(Fc_p)
        scalar mc_taols_Fa   = r(Fa)
        scalar mc_taols_Fa_p = r(Fa_p)
        scalar mc_taols_w    = r(weight)
        local has_taols = 1
    }

    * ---------------------------------------------------------------
    * Post results
    * ---------------------------------------------------------------
    ereturn post `Bhat' `Vhat', esample(`touse') depname(`yvar') obs(`Nrun')
    ereturn scalar N          = `Nrun'
    ereturn scalar K          = `nx'
    ereturn scalar level      = `level'
    ereturn scalar rss        = `rss'
    if !missing(real("`r2'"))   ereturn scalar r2   = `r2'
    if !missing(real("`lrse'")) ereturn scalar lrse = `lrse'
    ereturn local cmd         "multicoint"
    ereturn local cmdline     `"multicoint `0'"'
    ereturn local depvar      "`yvar'"
    ereturn local indepvars   "`xvars'"
    ereturn local estimator   "`estimator'"
    ereturn local test        "`test'"
    ereturn local trend       "`trend'"
    ereturn local kernel      "`kernel'"
    ereturn local autolag     "`autolag'"
    ereturn local title       "Multicointegration regression (`estimator')"
    ereturn local properties  "b V"
    ereturn local resvar      "_mc_uhat"
    ereturn local Ycumvar     "_mc_Ycum"
    ereturn local Xcumvars    "`Xcumperm'"

    if `has_gl' {
        ereturn scalar gl_stat = mc_gl_stat
        ereturn scalar gl_lags = mc_gl_lags
        ereturn scalar gl_p    = mc_gl_p
        ereturn scalar gl_cv05 = mc_gl_cv05
    }
    if `has_egh' {
        ereturn scalar egh_stat  = mc_egh_stat
        ereturn scalar egh_lags  = mc_egh_lags
        ereturn scalar egh_cv01  = mc_egh_cv01
        ereturn scalar egh_cv025 = mc_egh_cv025
        ereturn scalar egh_cv05  = mc_egh_cv05
        ereturn scalar egh_cv10  = mc_egh_cv10
    }
    if `has_taols' {
        ereturn scalar taols_Fm    = mc_taols_Fm
        ereturn scalar taols_Fm_p  = mc_taols_Fm_p
        ereturn scalar taols_Fc    = mc_taols_Fc
        ereturn scalar taols_Fc_p  = mc_taols_Fc_p
        ereturn scalar taols_Fa    = mc_taols_Fa
        ereturn scalar taols_Fa_p  = mc_taols_Fa_p
        ereturn scalar taols_w     = mc_taols_w
    }

    if "`notable'" == "" _mc_display
    if "`graph'"   != "" multicoint_graph
end


* =========================================================================
* _mc_display - pretty unicode-bordered tables
* =========================================================================
program define _mc_display
    di _n  ///
"{txt}{c TLC}{hline 78}{c TRC}"
    di  "{txt}{c |}  {bf:MULTICOINTEGRATION ANALYSIS}" _col(80) "{c |}"
    di  "{txt}{c LT}{hline 78}{c RT}"

    local trtxt "none"
    if "`e(trend)'" == "c"   local trtxt "constant"
    if "`e(trend)'" == "ct"  local trtxt "const+trend"
    if "`e(trend)'" == "ctt" local trtxt "const+t+t^2"

    local est_up = upper("`e(estimator)'")
    local test_up= upper("`e(test)'")
    local depv  = abbrev("`e(depvar)'",12)
    local indepv= abbrev("`e(indepvars)'",24)

    di as txt "{c |}  Dep. var (flow)   : " as res %-14s "`depv'"          ///
       as txt "  Estimator   : " as res %-12s "`est_up'"  _col(80) as txt "{c |}"
    di as txt "{c |}  Indep. vars       : " as res %-14s "`indepv'"        ///
       as txt "  Test(s)     : " as res %-12s "`test_up'" _col(80) as txt "{c |}"
    di as txt "{c |}  Deterministics    : " as res %-14s "`trtxt'"         ///
       as txt "  Sample N    : " as res %-12.0f e(N)        _col(80) as txt "{c |}"

    cap confirm scalar e(r2)
    if !_rc & e(r2) != . {
        di as txt "{c |}  R-squared         : " as res %-14.4f e(r2)        ///
           as txt "  RMSE        : " as res %-12.4f sqrt(e(rss)/e(N))         ///
           _col(80) as txt "{c |}"
    }
    cap confirm scalar e(lrse)
    if !_rc & e(lrse) != . {
        di as txt "{c |}  Long-run S.E.     : " as res %-14.4f e(lrse)      ///
           _col(80) as txt "{c |}"
    }
    di "{txt}{c BLC}{hline 78}{c BRC}"

    * Coefficient equation banner
    local eqstr "Y_t ="
    if "`e(trend)'" != "none" local eqstr "`eqstr' a"
    if "`e(trend)'" == "ct" | "`e(trend)'" == "ctt" local eqstr "`eqstr' + d1*t"
    if "`e(trend)'" == "ctt" local eqstr "`eqstr' + d2*t^2"
    local eqstr "`eqstr' + b'X_t + g'x_t + u_t"
    di _n as txt "{bf:Regression:  `eqstr'}"
    di as txt "  (X = cumulated I(2), x = flow I(1) - suffix _cum marks cumulated regressors)"

    ereturn display, level(`e(level)')

    if "`e(test)'" != "none" {
        di _n "{txt}{c TLC}{hline 78}{c TRC}"
        di "{txt}{c |}  {bf:TESTS OF MULTICOINTEGRATION}" _col(80) "{c |}"
        di "{txt}{c |}    H0: residual u_t is I(1) (no multicointegration)" _col(80) "{c |}"
        di "{txt}{c |}    H1: residual u_t is I(0) (multicointegration present)" _col(80) "{c |}"
        di "{txt}{c LT}{hline 78}{c RT}"
        di as txt "{c |} {bf:Test}" _col(38) "{bf:Statistic}" _col(54) "{bf:5% c.v.}"  ///
              _col(67) "{bf:Decision}" _col(80) "{c |}"
        di "{txt}{c LT}{hline 78}{c RT}"

        local nReject = 0
        local nTest   = 0

        cap confirm scalar e(gl_stat)
        if !_rc {
            local ++nTest
            local st = e(gl_stat)
            local cv = e(gl_cv05)
            local dec  "no reject "
            if `st' < `cv' {
                local dec "reject ** "
                local ++nReject
            }
            di as txt "{c |} Granger-Lee (1989,1990)" _col(38)               ///
               as res %9.3f `st' _col(54) as res %9.3f `cv' _col(67)         ///
               as res "`dec'" _col(80) as txt "{c |}"
        }
        cap confirm scalar e(egh_stat)
        if !_rc {
            local ++nTest
            local st = e(egh_stat)
            local cv = e(egh_cv05)
            local dec  "no reject "
            if `st' < `cv' {
                local dec "reject ** "
                local ++nReject
            }
            di as txt "{c |} Engsted-Gonzalo-Haldrup (1997)" _col(38)       ///
               as res %9.3f `st' _col(54) as res %9.3f `cv' _col(67)        ///
               as res "`dec'" _col(80) as txt "{c |}"
        }
        cap confirm scalar e(taols_Fa)
        if !_rc {
            local ++nTest
            local st = e(taols_Fa)
            local p  = e(taols_Fa_p)
            local cv = invF(e(K),e(N)-3*e(K)-1,0.95)
            local dec  "no reject "
            if !missing(`p') & `p' < 0.05 {
                local dec "reject ** "
                local ++nReject
            }
            di as txt "{c |} TAOLS adaptive F (Sun 2026)" _col(38)          ///
               as res %9.3f `st' _col(54) as res %9.3f `cv' _col(67)        ///
               as res "`dec'" _col(80) as txt "{c |}"
        }
        di "{txt}{c BLC}{hline 78}{c BRC}"

        if `nTest' > 0 {
            if `nReject' == `nTest' {
                di as res _n "  ==> Unanimous evidence in favour of multicointegration (`nReject'/`nTest' at 5%)"
            }
            else if `nReject' == 0 {
                di as txt _n "  ==> No evidence of multicointegration (0/`nTest')"
            }
            else {
                di as txt _n "  ==> Mixed evidence: `nReject'/`nTest' tests reject H0 at 5%"
            }
        }
        di as txt _n "  Residuals saved as " as res "_mc_uhat" as txt        ///
                  ";  cumulated series: " as res "_mc_Ycum  _mc_Xcum*"
        di as txt "  Diagnostic graphs: " as res "multicoint_graph"          ///
                  as txt "  |  Critical values: " as res "multicoint_cv"
    }
end
