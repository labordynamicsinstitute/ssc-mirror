*! xtmulticointgrat v1.0.0  22may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Panel multicointegration tests with common factors
*! ---------------------------------------------------------------------------
*! Reference:
*!   Berenguer-Rico, V. & Carrion-i-Silvestre, J.Ll. (2006).
*!   "Testing for Multicointegration in Panel Data with Common Factors."
*!   Oxford Bulletin of Economics and Statistics, 68 (Supplement), 721-744.
*!
*! Related GAUSS code by V. Berenguer-Rico & J.Ll. Carrion-i-Silvestre, AQR
*! Research Group, University of Barcelona.
*!
*! Two testing branches:
*!   (A) cross-section independent
*!         -> Pedroni-style between-dimension Z_rho_NT, Z_t_NT statistics on
*!            the one-step Engsted-Gonzalo-Haldrup (1997) multicoint regression
*!            Y_{i,t} = Cm_t mu_i + X_{i,t} beta_i + x_{i,t} gamma_i + u_{i,t}
*!         -> standardized using Monte-Carlo moments Theta_1, Psi_1, Theta_2, Psi_2
*!            from Tables 1 and 2 of the paper.
*!
*!   (B) cross-section dependent via approximate common factors
*!         -> Granger-Lee two-step regression
*!              Stage 1:  y_{i,t} = c_t alpha_i + x_{i,t} beta_i + ϑ_{i,t}
*!              Stage 2:  y_{i,t} = m_t mu_i + S_{i,t} gamma_i + u_{i,t}
*!         -> PANIC (Bai-Ng 2004) factor extraction on Δu_{i,t}
*!            with panel BIC (IC_p1, IC_p2, IC_p3, BIC3) for r-hat
*!         -> pooled ADF on cumulated idiosyncratic component (Table 3 moments)
*!         -> per-factor ADF / MQ_c for non-stationary common stochastic trends
*! ---------------------------------------------------------------------------

program define xtmulticointgrat, rclass
    version 14.0

    if replay() {
        if "`r(cmd)'" == "xtmulticointgrat" {
            _xtmcg_display
            exit
        }
    }

    syntax varlist(min=2 numeric ts) [if] [in], [    ///
        TRend(string)                                  ///
        APProach(string)                               ///
        FACtors                                        ///
        Rmax(integer 6)                                ///
        IC(string)                                     ///
        PMAX(integer 5)                                ///
        LAGSel(string)                                 ///
        LAGS(integer 0)                                ///
        Level(cilevel)                                 ///
        GRaph                                          ///
        GRSave(string)                                 ///
        NOTABle                                        ///
        ]

    * --- load mata engine ----------------------------------------------------
    qui capture mata: __xtmcg_loaded()
    if _rc qui _xtmcg_mata

    * --- defaults ------------------------------------------------------------
    if "`trend'"   == "" local trend   "c"
    if "`approach'"== "" local approach "auto"
    if "`ic'"      == "" local ic      "ic2"
    if "`lagsel'"  == "" local lagsel  "tsig"

    local trend    = lower("`trend'")
    local approach = lower("`approach'")
    local ic       = lower("`ic'")
    local lagsel   = lower("`lagsel'")

    if !inlist("`trend'","none","c","ct","ctt") {
        di as err "trend() must be one of: none c ct ctt"
        exit 198
    }
    if !inlist("`approach'","auto","indep","factors") {
        di as err "approach() must be one of: auto indep factors"
        exit 198
    }
    if !inlist("`ic'","ic1","ic2","ic3","bic3") {
        di as err "ic() must be one of: ic1 ic2 ic3 bic3"
        exit 198
    }
    if !inlist("`lagsel'","tsig","aic","bic","hqic","fixed") {
        di as err "lagsel() must be one of: tsig aic bic hqic fixed"
        exit 198
    }
    if "`factors'" != "" local approach "factors"

    * --- xtset panel ---------------------------------------------------------
    qui xtset
    local ivar = r(panelvar)
    local tvar = r(timevar)
    if "`ivar'" == "" | "`tvar'" == "" {
        di as err "panel data not set; use {bf:xtset} first"
        exit 459
    }

    marksample touse
    markout `touse' `varlist'

    gettoken yvar xvars : varlist
    local m1 : word count `xvars'     // number of I(1) flow regressors per i

    qui levelsof `ivar' if `touse', local(pids)
    local N : word count `pids'
    if `N' < 2 {
        di as err "need at least 2 panel units (got `N')"
        exit 2001
    }

    qui summ `tvar' if `touse'
    local Tmin = r(min)
    local Tmax = r(max)
    local T    = `Tmax' - `Tmin' + 1

    * Check that panel is balanced - required for matrix layout
    qui by `ivar': gen byte _xtmcg_obs = `touse'
    qui by `ivar': egen long _xtmcg_n = sum(_xtmcg_obs)
    qui summ _xtmcg_n
    local Tmin_i = r(min)
    local Tmax_i = r(max)
    cap drop _xtmcg_obs _xtmcg_n
    if `Tmin_i' != `Tmax_i' {
        di as err "panel must be balanced (each i must have the same T)"
        di as err "min T per i = `Tmin_i', max T per i = `Tmax_i'"
        exit 2001
    }
    local T = `Tmin_i'
    if `T' < 25 {
        di as err "need at least 25 time observations per panel (got `T')"
        exit 2001
    }

    * --- build T x N matrices: Y (depvar) and X (flow regressors stacked) ----
    sort `ivar' `tvar'
    tempname Ymat Xmat Xcum
    mata: _xtmcg_build_matrices("`yvar'", "`xvars'", "`ivar'", "`tvar'", ///
                                  "`touse'", "`Ymat'", "`Xmat'", "`Xcum'")

    * In the independent branch (one-step) we use X (I(1) flows) and Xcum (I(2))
    * with m1 (flow) and m2 (cumulated) = number of regressors.
    local m2 = `m1'

    * Auto-pick approach: factors if N is large enough that PCA makes sense AND
    * cross-section dependence is suspected.  Default: factors unless user picks indep.
    if "`approach'" == "auto" {
        local approach "factors"
    }

    * ========================================================================
    * BRANCH A: cross-section independent  (Pedroni between-dim Z_rho, Z_t)
    * ========================================================================
    if "`approach'" == "indep" {
        tempname ADFtab Pool
        mata: _xtmcg_pedroni_indep("`Ymat'", "`Xmat'", "`Xcum'", `m1', `m2',     ///
                                   "`trend'", `pmax', "`lagsel'",                 ///
                                   "`ADFtab'", "`Pool'")
        local Z_rho_pool   = `Pool'[1,1]
        local Z_t_pool     = `Pool'[1,2]
        local Z_rho_std    = `Pool'[1,3]
        local Z_t_std      = `Pool'[1,4]
        local Theta1       = `Pool'[1,5]
        local Psi1         = `Pool'[1,6]
        local Theta2       = `Pool'[1,7]
        local Psi2         = `Pool'[1,8]
        local Nused        = `Pool'[1,9]

        local pval_rho = normal(`Z_rho_std')
        local pval_t   = normal(`Z_t_std')

        if "`notable'" == "" {
            _xtmcg_disp_indep, yvar(`yvar') xvars(`xvars')                       ///
                m1(`m1') m2(`m2') trend(`trend')                                  ///
                npan(`Nused') tobs(`T')                                            ///
                zr(`Z_rho_pool')  zt(`Z_t_pool')                                   ///
                zrstd(`Z_rho_std') ztstd(`Z_t_std')                                ///
                prho(`pval_rho') ptt(`pval_t')                                     ///
                th1(`Theta1') ps1(`Psi1')                                          ///
                th2(`Theta2') ps2(`Psi2')
        }

        * Persist results to permanent matrices/globals (survive across commands)
        cap matrix drop _xtmcg_adf_indiv _xtmcg_loadings _xtmcg_mq_factors
        matrix _xtmcg_adf_indiv = `ADFtab'
        global XTMCG_N        `Nused'
        global XTMCG_T        `T'
        global XTMCG_R        0
        global XTMCG_Q        0
        global XTMCG_TREND    `trend'
        global XTMCG_DEPVAR   `yvar'
        global XTMCG_INDEP    `xvars'
        global XTMCG_APPROACH indep
        local adfcv_indep      = -2.86
        if "`trend'" == "ct" | "`trend'" == "ctt" local adfcv_indep = -3.41
        if "`trend'" == "none"                    local adfcv_indep = -1.95
        global XTMCG_ACV      `adfcv_indep'

        return clear
        return scalar N        = `Nused'
        return scalar T        = `T'
        return scalar m1       = `m1'
        return scalar m2       = `m2'
        return scalar Z_rho    = `Z_rho_pool'
        return scalar Z_t      = `Z_t_pool'
        return scalar Z_rho_std= `Z_rho_std'
        return scalar Z_t_std  = `Z_t_std'
        return scalar p_rho    = `pval_rho'
        return scalar p_t      = `pval_t'
        return scalar Theta1   = `Theta1'
        return scalar Psi1     = `Psi1'
        return scalar Theta2   = `Theta2'
        return scalar Psi2     = `Psi2'
        return matrix adf_indiv = `ADFtab'
        return local cmd     "xtmulticointgrat"
        return local depvar  "`yvar'"
        return local indep   "`xvars'"
        return local trend   "`trend'"
        return local approach "indep"

        if "`graph'" != "" {
            xtmulticointgrat_graph, save(`grsave')
        }
        exit
    }

    * ========================================================================
    * BRANCH B: common factors  (PANIC + pooled ADF on idiosyncratic + MQ_c)
    * ========================================================================
    tempname Smat Umat Fhat Lhat Ehat
    mata: _xtmcg_twostep_resid("`Ymat'", "`Xmat'", `m1', "`trend'", "`Smat'", "`Umat'")

    tempname rsel
    mata: _xtmcg_panic("`Umat'", "`trend'", `rmax', "`ic'",                       ///
                       "`Fhat'", "`Lhat'", "`Ehat'", "`rsel'")
    local rstar = `rsel'

    * Pooled idiosyncratic ADF (Table 3 moments)
    tempname IdioADF IdioPool
    mata: _xtmcg_pool_idio_adf("`Ehat'", "`trend'", `pmax', "`lagsel'",            ///
                                "`IdioADF'", "`IdioPool'")
    local Zbar_idio = `IdioPool'[1,1]
    local Zstd_idio = `IdioPool'[1,2]
    local Theta_e   = `IdioPool'[1,3]
    local Psi_e     = `IdioPool'[1,4]
    local Nused     = `IdioPool'[1,5]
    local Teff      = `IdioPool'[1,6]
    local p_idio    = normal(`Zstd_idio')

    * MQ test on the common factors
    tempname MQout
    mata: _xtmcg_mq_test("`Fhat'", "`trend'", `pmax', "`lagsel'", "`MQout'")

    * Count non-stationary factors using approximate ADF c.v.
    *   (constant: -2.86 at 5%;  trend: -3.41 at 5%;  no det: -1.95)
    local adf_cv = -2.86
    if "`trend'" == "ct" | "`trend'" == "ctt" local adf_cv = -3.41
    if "`trend'" == "none"                    local adf_cv = -1.95

    local q_nonstat = 0
    forvalues j = 1/`rstar' {
        local tj = `MQout'[`j', 2]
        if `tj' > `adf_cv' local ++q_nonstat
    }

    * Persist factor variables and residual variables
    cap drop _xtmcg_e_*
    cap drop _xtmcg_F*
    cap drop _xtmcg_u_*
    cap drop _xtmcg_S_*
    mata: _xtmcg_persist("`Smat'", "`Umat'", "`Ehat'", "`Fhat'",                  ///
                         "`ivar'", "`tvar'", "`touse'")

    if "`notable'" == "" {
        _xtmcg_disp_factors, yvar(`yvar') xvars(`xvars')                          ///
            m1(`m1') trend(`trend') ic(`ic') lagsel(`lagsel') pmax(`pmax')         ///
            npan(`Nused') tobs(`T') rstar(`rstar') qnon(`q_nonstat')               ///
            zraw(`Zbar_idio') zstd(`Zstd_idio') pval(`p_idio')                     ///
            theta(`Theta_e') psi(`Psi_e') acv(`adf_cv')                            ///
            mqout(`MQout') loadings(`Lhat') adfidio(`IdioADF')
    }

    * Persist results to permanent matrices/globals (survive across commands)
    cap matrix drop _xtmcg_adf_idio _xtmcg_loadings _xtmcg_mq_factors
    matrix _xtmcg_adf_idio   = `IdioADF'
    matrix _xtmcg_loadings   = `Lhat'
    matrix _xtmcg_mq_factors = `MQout'
    global XTMCG_N        `Nused'
    global XTMCG_T        `T'
    global XTMCG_R        `rstar'
    global XTMCG_Q        `q_nonstat'
    global XTMCG_TREND    `trend'
    global XTMCG_DEPVAR   `yvar'
    global XTMCG_INDEP    `xvars'
    global XTMCG_APPROACH factors
    global XTMCG_ACV      `adf_cv'

    return clear
    return scalar N       = `Nused'
    return scalar T       = `T'
    return scalar m1      = `m1'
    return scalar r       = `rstar'
    return scalar q_nonstat = `q_nonstat'
    return scalar Z_idio  = `Zbar_idio'
    return scalar Z_idio_std = `Zstd_idio'
    return scalar p_idio  = `p_idio'
    return scalar Theta_e = `Theta_e'
    return scalar Psi_e   = `Psi_e'
    return matrix adf_idio   = `IdioADF'
    return matrix mq_factors = `MQout'
    return matrix loadings   = `Lhat'
    return local cmd     "xtmulticointgrat"
    return local depvar  "`yvar'"
    return local indep   "`xvars'"
    return local trend   "`trend'"
    return local approach "factors"
    return local ic       "`ic'"
    return local lagsel   "`lagsel'"

    if "`graph'" != "" {
        xtmulticointgrat_graph, save(`grsave')
    }
end


* ===========================================================================
* DISPLAY PROGRAMS
* ===========================================================================
program define _xtmcg_disp_indep
    syntax, yvar(name) xvars(string) m1(integer) m2(integer) trend(string)   ///
            npan(integer) tobs(integer)                                       ///
            zr(real) zt(real) zrstd(real) ztstd(real)                         ///
            prho(real) ptt(real)                                              ///
            th1(real) ps1(real) th2(real) ps2(real)

    local trtxt = "none"
    if "`trend'" == "c"   local trtxt "constant"
    if "`trend'" == "ct"  local trtxt "constant + trend"
    if "`trend'" == "ctt" local trtxt "constant + trend + trend^2"

    local depv = abbrev("`yvar'", 16)
    local indv = abbrev("`xvars'", 28)

    di _n  ///
"{txt}{c TLC}{hline 78}{c TRC}"
    di     "{txt}{c |}  {bf:PANEL MULTICOINTEGRATION TEST -- cross-section independent case}" ///
                                                                            _col(80) "{c |}"
    di     "{txt}{c |}  Berenguer-Rico & Carrion-i-Silvestre (2006, OBES)"   _col(80) "{c |}"
    di     "{txt}{c LT}{hline 78}{c RT}"
    di as txt "{c |}  Dep. var (flow)   : " as res %-16s "`depv'"                            ///
       as txt "  N (panels)  : " as res %-6.0f `npan'    _col(80) as txt "{c |}"
    di as txt "{c |}  Indep. vars (flow): " as res %-16s "`indv'"                            ///
       as txt "  T (periods) : " as res %-6.0f `tobs'    _col(80) as txt "{c |}"
    di as txt "{c |}  Deterministics    : " as res %-16s "`trtxt'"                           ///
       as txt "  m1 / m2     : " as res %-2.0f `m1' "/" %-2.0f `m2' "   "  _col(80) as txt "{c |}"
    di "{txt}{c BLC}{hline 78}{c BRC}"

    di _n as txt "{bf:One-step Engsted-Gonzalo-Haldrup regression:}"
    di as txt "    Y_i,t = Cm_t mu_i + X_i,t beta_i + x_i,t gamma_i + u_i,t"
    di as txt "    Y = cumsum(y), X = cumsum(x) are I(2);  x are I(1) flows."

    di _n "{txt}{c TLC}{hline 78}{c TRC}"
    di    "{txt}{c |}  {bf:POOLED PANEL STATISTICS (between-dimension)}"             _col(80) "{c |}"
    di    "{txt}{c |}    H0: residual u_i,t is I(1) (no multicointegration)"          _col(80) "{c |}"
    di    "{txt}{c |}    H1: residual u_i,t is I(0) (multicointegration present)"     _col(80) "{c |}"
    di    "{txt}{c LT}{hline 78}{c RT}"
    di as txt "{c |}  {bf:Statistic}"  _col(28) "{bf:Raw}" _col(43) "{bf:Standard.}"        ///
              _col(58) "{bf:p-value}" _col(72) "{bf:Decision}" _col(80) "{c |}"
    di    "{txt}{c LT}{hline 78}{c RT}"

    local decr "no reject"
    if `prho' < 0.05 local decr "reject **"
    if `prho' < 0.01 local decr "reject ***"
    di as txt "{c |}  Z_rho_NT (norm. bias)" _col(28)                                         ///
       as res %10.3f `zr' _col(43) as res %10.3f `zrstd'                                       ///
       _col(58) as res %8.4f `prho' _col(72) as res "`decr'"  _col(80) as txt "{c |}"

    local dect "no reject"
    if `ptt' < 0.05 local dect "reject **"
    if `ptt' < 0.01 local dect "reject ***"
    di as txt "{c |}  Z_t_NT   (t-ratio)   " _col(28)                                         ///
       as res %10.3f `zt' _col(43) as res %10.3f `ztstd'                                       ///
       _col(58) as res %8.4f `ptt' _col(72) as res "`dect'" _col(80) as txt "{c |}"

    di "{txt}{c LT}{hline 78}{c RT}"
    di as txt "{c |}  Moments (Tables 1-2, BR-CS 2006): " _col(80) "{c |}"
    di as txt "{c |}    Theta_1 = " as res %7.3f `th1' as txt "  Psi_1 = "      ///
              as res %7.3f `ps1'                                                 ///
              "   Theta_2 = " as res %7.3f `th2' as txt "  Psi_2 = "             ///
              as res %7.3f `ps2' _col(80) as txt "{c |}"
    di "{txt}{c BLC}{hline 78}{c BRC}"
    di _n as txt "  Critical values (one-sided lower-tail standardized N(0,1)):"
    di as txt "    1%: -2.326    5%: -1.645    10%: -1.282"
end


program define _xtmcg_disp_factors
    syntax, yvar(name) xvars(string) m1(integer) trend(string)                ///
            ic(string) lagsel(string) pmax(integer)                            ///
            npan(integer) tobs(integer) rstar(integer) qnon(integer)           ///
            zraw(real) zstd(real) pval(real)                                   ///
            theta(real) psi(real) acv(real)                                    ///
            mqout(name) loadings(name) adfidio(name)

    local trtxt = "none"
    if "`trend'" == "c"   local trtxt "constant"
    if "`trend'" == "ct"  local trtxt "constant + trend"
    if "`trend'" == "ctt" local trtxt "constant + trend + trend^2"

    local depv = abbrev("`yvar'", 16)
    local indv = abbrev("`xvars'", 28)

    di _n  ///
"{txt}{c TLC}{hline 78}{c TRC}"
    di     "{txt}{c |}  {bf:PANEL MULTICOINTEGRATION TEST -- common factor approach}"          _col(80) "{c |}"
    di     "{txt}{c |}  Berenguer-Rico & Carrion-i-Silvestre (2006, OBES)" _col(80) "{c |}"
    di     "{txt}{c LT}{hline 78}{c RT}"
    di as txt "{c |}  Dep. var (flow)   : " as res %-16s "`depv'"                                ///
       as txt "  N (panels)  : " as res %-6.0f `npan' _col(80) as txt "{c |}"
    di as txt "{c |}  Indep. vars (flow): " as res %-16s "`indv'"                                ///
       as txt "  T (periods) : " as res %-6.0f `tobs' _col(80) as txt "{c |}"
    di as txt "{c |}  Deterministics    : " as res %-16s "`trtxt'"                               ///
       as txt "  Factor IC   : " as res %-6s "`ic'" _col(80) as txt "{c |}"
    di as txt "{c |}  Lag selection     : " as res %-16s "`lagsel'"                              ///
       as txt "  ADF lag max : " as res %-6.0f `pmax' _col(80) as txt "{c |}"
    di "{txt}{c BLC}{hline 78}{c BRC}"

    di _n as txt "{bf:Granger-Lee (1989) two-step procedure with PANIC factors:}"
    di as txt "    Stage 1:  y_i,t = c_t alpha_i + x_i,t beta_i  + ϑ_i,t"
    di as txt "    Stage 2:  y_i,t = m_t mu_i    + S_i,t gamma_i + u_i,t,    S_i,t = sum(ϑ_i,j)"
    di as txt "    u_i,t = F_t pi_i + e_i,t      (PANIC on Δu, Bai-Ng 2004)"

    di _n "{txt}{c TLC}{hline 78}{c TRC}"
    di    "{txt}{c |}  {bf:STEP 1: number of common factors selected by `ic'}"      _col(80) "{c |}"
    di    "{txt}{c LT}{hline 78}{c RT}"
    di as txt "{c |}      r-hat (estimated number of factors)        = "                     ///
              as res %3.0f `rstar' _col(80) as txt "{c |}"
    di "{txt}{c BLC}{hline 78}{c BRC}"

    if `rstar' > 0 {
        di _n "{txt}{c TLC}{hline 78}{c TRC}"
        di    "{txt}{c |}  {bf:STEP 2: MQ test on common stochastic trends among r-hat factors}" _col(80) "{c |}"
        di    "{txt}{c LT}{hline 78}{c RT}"
        di as txt "{c |}   Factor j" _col(20) "ADF t-stat" _col(38) "Sum phi" _col(54)        ///
                  "Lag" _col(64) "Decision" _col(80) "{c |}"
        di    "{txt}{c LT}{hline 78}{c RT}"
        forvalues j = 1/`rstar' {
            local tj = `mqout'[`j', 2]
            local sp = `mqout'[`j', 3]
            local lj = `mqout'[`j', 4]
            local decj "I(1) factor"
            if `tj' < `acv' local decj "I(0) factor"
            di as txt "{c |}     " as res %2.0f `j' _col(20) %10.3f `tj'                       ///
               _col(38) %10.3f `sp' _col(54) %4.0f `lj'                                         ///
               _col(64) "`decj'" _col(80) as txt "{c |}"
        }
        di "{txt}{c LT}{hline 78}{c RT}"
        di as txt "{c |}   Common stochastic trends (q-hat)  =  " as res %3.0f `qnon'           ///
                  as txt "                              " _col(80) "{c |}"
        di as txt "{c |}   ADF 5% c.v. used = " as res %6.3f `acv' as txt                       ///
                  "  (trend = `trend')" _col(80) "{c |}"
        di "{txt}{c BLC}{hline 78}{c BRC}"
    }

    di _n "{txt}{c TLC}{hline 78}{c TRC}"
    di    "{txt}{c |}  {bf:STEP 3: Pooled ADF on idiosyncratic component (BR-CS 2006, Thm 2)}" _col(80) "{c |}"
    di    "{txt}{c |}    H0: e_i,t has a unit root (no multicointegration in idiosyncratic)"   _col(80) "{c |}"
    di    "{txt}{c |}    H1: e_i,t is stationary"                                              _col(80) "{c |}"
    di    "{txt}{c LT}{hline 78}{c RT}"

    local dec "no reject"
    if `pval' < 0.05 local dec "reject **"
    if `pval' < 0.01 local dec "reject ***"

    di as txt "{c |}  Z_bar^e (raw pooled)" _col(36) as res %10.3f `zraw'         _col(80) as txt "{c |}"
    di as txt "{c |}  Z_bar^e (standardised N(0,1))" _col(36) as res %10.3f `zstd' _col(80) as txt "{c |}"
    di as txt "{c |}  Asymptotic p-value (lower)"  _col(36) as res %10.4f `pval' _col(80) as txt "{c |}"
    di as txt "{c |}  Decision at 5%"               _col(36) as res "`dec'"      _col(80) as txt "{c |}"
    di as txt "{c |}  Theta_e = " as res %7.3f `theta'                                         ///
              as txt "    Psi_e = " as res %7.3f `psi'                                         ///
              as txt "    (Table 3, BR-CS 2006)" _col(80) "{c |}"
    di "{txt}{c BLC}{hline 78}{c BRC}"

    di _n "{txt}{c TLC}{hline 78}{c TRC}"
    di    "{txt}{c |}  {bf:OVERALL CONCLUSION}"                                                _col(80) "{c |}"
    di    "{txt}{c LT}{hline 78}{c RT}"
    if `pval' < 0.05 & `qnon' == 0 {
        di as txt "{c |}  " as res "Strong evidence of panel multicointegration."              _col(80) as txt "{c |}"
        di as txt "{c |}  " as res "Both common-factor and idiosyncratic components support H1." _col(80) as txt "{c |}"
    }
    else if `pval' < 0.05 & `qnon' > 0 {
        di as txt "{c |}  " as res "Mild / partial multicointegration."                        _col(80) as txt "{c |}"
        di as txt "{c |}  " as res "Idiosyncratic component stationary, but " %2.0f `qnon'     ///
                                  " non-stationary factors remain." _col(80) as txt "{c |}"
    }
    else {
        di as txt "{c |}  " as res "No evidence of panel multicointegration."                  _col(80) as txt "{c |}"
        di as txt "{c |}  " as res "Idiosyncratic component still unit-root."                  _col(80) as txt "{c |}"
    }
    di "{txt}{c BLC}{hline 78}{c BRC}"

    di _n as txt "  Saved variables:"
    di as txt "    " as res "_xtmcg_S_i"   as txt " - first-stage cumulated residual S_i,t"
    di as txt "    " as res "_xtmcg_u_i"   as txt " - second-stage residual u_i,t"
    di as txt "    " as res "_xtmcg_e_i"   as txt " - idiosyncratic component e_i,t (PANIC)"
    di as txt "    " as res "_xtmcg_F1..F`rstar'" as txt " - estimated common factors"
    di as txt "  Companion: " as res "xtmulticointgrat_graph"                                  ///
              as txt "  |  Help: " as res "help xtmulticointgrat"
end


* ===========================================================================
* MATA helpers live in _xtmcg_mata.mata so they're available globally.
* ===========================================================================
