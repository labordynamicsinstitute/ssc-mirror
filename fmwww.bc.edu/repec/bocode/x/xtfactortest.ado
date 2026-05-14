*! xtfactortest 1.0.0  -  12 May 2026
*! Author : Dr Merwan Roudane  <merwanroudane920@gmail.com>
*!
*! ============================================================================
*!  xtfactortest -- Specification tests for heterogeneous panels with
*!                  interactive (multifactor) error effects
*! ============================================================================
*!
*!  Model
*!  -----
*!      y_it = beta_i' x_it + gamma_i' f_t + eps_it
*!      x_it = Lambda_i' f_t + v_it                      i=1..N , t=1..T
*!
*!  Tests implemented
*!  -----------------
*!  hb        HB-CCE test of heterogeneity bias in the pooled CCE estimator.
*!            H0 : E[ X_i' M_Fhat X_i ( beta_i - beta_CCEMG ) ] = 0
*!            Reference :
*!              Juodis & Reese (2026, J.Econometrics 253:106120) Lesson 2
*!              modifies the FE-based HB test of
*!              Campello, Galvao & Juhl (2019, JBES 37(4):749-760).
*!
*!  lm        LM-X test for conditional independence (regressors vs loadings).
*!            H0 : E[ gamma_i - bar_gamma | x_it, f_t ] = 0
*!            Reference :
*!              Kapetanios, Serlenga & Shin (2024, JBES 42(2):743-761).
*!
*!  hausman   Hausman-type test for correlated factor loadings (FE vs CCE).
*!            Reference :
*!              Kapetanios, Serlenga & Shin (2023, Empirical Economics
*!              64:2611-2659).  CCE-MG is used as a consistent proxy for
*!              the bias-corrected PC estimator (Westerlund 2019b, H_W).
*!
*!  joint     HBFB joint test for either heterogeneity bias OR factor-omission
*!            bias in 2W-FE.   Reference : Juodis & Reese (2026), App. A.2.2.
*!
*!  all       Runs all four tests, prints summary table, decision rule, graphs.
*!
*!  Companion :  Ditzen (2018) xtdcce2 for full CCE / DCCE estimation.
*! ============================================================================


capture program drop xtfactortest
program define xtfactortest, rclass
    version 16.0

    /* dispatch on subcommand */
    gettoken sub 0 : 0, parse(" ,")
    local sub = lower("`sub'")
    if !inlist("`sub'", "hb", "lm", "hausman", "joint", "all") {
        di as err `"unknown subcommand "`sub'""'
        di as err `"  valid : hb | lm | hausman | joint | all"'
        exit 198
    }

    syntax varlist(min=2 numeric ts) [if] [in]      ///
        [ ,                                          ///
            CRoss(varlist)                           ///
            POoled                                   ///
            NPC(integer 1)                           ///
            Level(cilevel)                           ///
            NOGraph                                  ///
            GRaphsave(string)                        ///
            REPlace                                  ///
            NOHeader                                 ///
            COMPACT                                  ///
        ]

    marksample touse
    markout `touse' `varlist' `cross', strok

    qui xtset
    if "`r(panelvar)'" == "" {
        di as err "panel not -xtset- ; use {stata xtset}{cmd:.}"
        exit 459
    }
    local id  = "`r(panelvar)'"
    local tm  = "`r(timevar)'"
    if "`tm'" == "" {
        di as err "a time variable is required ; use {stata xtset `id' timevar}"
        exit 459
    }

    tokenize `varlist'
    local depvar `1'
    macro shift
    local indepvars `*'
    local K : word count `indepvars'

    /* require balanced panel */
    tempvar tag
    qui by `id' `tm' : gen byte `tag' = (_n == 1) if `touse'
    qui count if `tag' & `touse'
    local NT = r(N)
    qui levelsof `id' if `touse', local(idlist)
    local N : word count `idlist'
    qui levelsof `tm' if `touse', local(tmlist)
    local T : word count `tmlist'

    if `NT' != `N' * `T' {
        di as err "xtfactortest requires a balanced panel"
        di as err "  (NT = `NT' but N*T = " `N'*`T' ")"
        exit 459
    }
    if "`level'" == "" local level 95

    /* ensure data sorted by panel, time for Mata reshape */
    sort `id' `tm'

    if "`sub'" == "hb"      _xtft_hb,     depvar(`depvar') indepvars(`indepvars') ///
                                          id(`id') tm(`tm') touse(`touse')         ///
                                          cross(`cross') level(`level')            ///
                                          `nograph' graphsave(`graphsave')         ///
                                          `replace' `noheader' `compact'
    if "`sub'" == "lm"      _xtft_lm,     depvar(`depvar') indepvars(`indepvars') ///
                                          id(`id') tm(`tm') touse(`touse')         ///
                                          npc(`npc') level(`level')                ///
                                          `nograph' graphsave(`graphsave')         ///
                                          `replace' `noheader' `compact'
    if "`sub'" == "hausman" _xtft_haus,   depvar(`depvar') indepvars(`indepvars') ///
                                          id(`id') tm(`tm') touse(`touse')         ///
                                          cross(`cross') level(`level')            ///
                                          `nograph' graphsave(`graphsave')         ///
                                          `replace' `noheader' `compact'
    if "`sub'" == "joint"   _xtft_joint,  depvar(`depvar') indepvars(`indepvars') ///
                                          id(`id') tm(`tm') touse(`touse')         ///
                                          cross(`cross') level(`level')            ///
                                          `nograph' graphsave(`graphsave')         ///
                                          `replace' `noheader' `compact'
    if "`sub'" == "all"     _xtft_all,    depvar(`depvar') indepvars(`indepvars') ///
                                          id(`id') tm(`tm') touse(`touse')         ///
                                          cross(`cross') level(`level')            ///
                                          npc(`npc')                               ///
                                          `nograph' graphsave(`graphsave')         ///
                                          `replace' `noheader'
end


* ============================================================================ *
*  _xtft_hb  --  HB-CCE test                                                   *
*  Juodis & Reese (2026), Lesson 2 ; modifies Campello et al. (2019)           *
* ============================================================================ *
capture program drop _xtft_hb
program define _xtft_hb, rclass
    syntax , depvar(varname) indepvars(varlist) id(varname) tm(varname)        ///
             touse(varname) [ cross(varlist) level(cilevel)                    ///
                              NOGraph graphsave(string) REPlace                ///
                              NOHeader COMPACT ]

    mata : _xtft_run_hb("`depvar'", "`indepvars'", "`id'", "`tm'", "`touse'")

    tempname bMG VarMG bI dHB
    scalar  HBs  = r(HB)
    scalar  pvs  = r(pvalue)
    scalar  Ks   = r(K)
    scalar  Ns   = r(N)
    scalar  Ts   = r(T)
    matrix `bMG'   = r(beta_CCEMG)
    matrix `VarMG' = r(Var_CCEMG)
    matrix `bI'    = r(beta_i)
    matrix `dHB'   = r(delta_HB)

    if "`noheader'" == "" {
        _xtft_header "HB-CCE test of heterogeneity bias in pooled CCE"          ///
            "Juodis & Reese (2026, J.Econometrics) Lesson 2"                    ///
            "modifies Campello, Galvao & Juhl (2019, JBES)"                     ///
            `=scalar(Ns)' `=scalar(Ts)' `=scalar(Ks)'
    }
    di
    di as text "{hline 78}"
    di as text "  H0 : E[X_i' M_Fhat X_i (beta_i - beta_CCEMG)] = 0_K"
    di as text "  H1 : individual slopes beta_i are correlated with"
    di as text "       X_i' M_Fhat X_i  (CCE residual-maker variation)"
    di as text "{hline 78}"
    _xtft_one_stat "HB-CCE" `=scalar(HBs)' `=scalar(Ks)' `=scalar(pvs)' `level'

    if "`compact'" == "" {
        tempname seMG
        matrix `seMG' = J(1, `=scalar(Ks)', .)
        forvalues k = 1/`=scalar(Ks)' {
            matrix `seMG'[1,`k'] = sqrt(`VarMG'[`k',`k'])
        }
        di
        di as text "  CCE-MG mean-group coefficients (Pesaran 2006 nonparametric SE):"
        _xtft_coef_table `bMG' `seMG' "`indepvars'" `level'
    }

    if "`nograph'" == "" {
        _xtft_graph_hb `bI', indepvars(`indepvars') graphsave(`graphsave') `replace'
    }

    return scalar HB     = scalar(HBs)
    return scalar pvalue = scalar(pvs)
    return scalar df     = scalar(Ks)
    return scalar N      = scalar(Ns)
    return scalar T      = scalar(Ts)
    return scalar K      = scalar(Ks)
    return local  test   "HB-CCE"
    return local  ref    "Juodis & Reese (2026, JoE) Lesson 2"
    return matrix beta_CCEMG = `bMG'
    return matrix Var_CCEMG  = `VarMG'
    return matrix beta_i     = `bI'
    return matrix delta_HB   = `dHB'

    scalar drop HBs pvs Ks Ns Ts
end


* ============================================================================ *
*  _xtft_lm  --  LM-X test                                                     *
*  Kapetanios, Serlenga & Shin (2024, JBES 42:743-761)                         *
* ============================================================================ *
capture program drop _xtft_lm
program define _xtft_lm, rclass
    syntax , depvar(varname) indepvars(varlist) id(varname) tm(varname)        ///
             touse(varname) [ npc(integer 1) level(cilevel)                    ///
                              NOGraph graphsave(string) REPlace                ///
                              NOHeader COMPACT ]

    mata : _xtft_run_lm("`depvar'", "`indepvars'", "`id'", "`tm'", "`touse'", `npc')

    tempname diagLM
    scalar  LMs  = r(LM)
    scalar  pvs  = r(pvalue)
    scalar  Ks   = r(K)
    scalar  Ns   = r(N)
    scalar  Ts   = r(T)
    matrix `diagLM' = r(diag_lm)

    if "`noheader'" == "" {
        _xtft_header "LM-X test for conditional independence" ///
            "Kapetanios, Serlenga & Shin (2024, JBES 42:743-761)" ///
            "FE residuals + first `npc' principal component(s) of regressors" ///
            `=scalar(Ns)' `=scalar(Ts)' `=scalar(Ks)'
    }
    di
    di as text "{hline 78}"
    di as text "  H0 : E[gamma_i - bar_gamma | x_it, f_t] = 0"
    di as text "       => 2W-FE remains consistent under multifactor errors"
    di as text "  H1 : regressors x_it correlated with factor loadings gamma_i"
    di as text "       => 2W-FE inconsistent; use PC/CCE"
    di as text "{hline 78}"
    _xtft_one_stat "LM-X" `=scalar(LMs)' `=scalar(Ks)' `=scalar(pvs)' `level'

    if "`nograph'" == "" {
        _xtft_graph_lm `diagLM', indepvars(`indepvars') graphsave(`graphsave') `replace'
    }

    return scalar LM     = scalar(LMs)
    return scalar pvalue = scalar(pvs)
    return scalar df     = scalar(Ks)
    return scalar N      = scalar(Ns)
    return scalar T      = scalar(Ts)
    return scalar K      = scalar(Ks)
    return scalar npc    = `npc'
    return local  test   "LM-X"
    return local  ref    "Kapetanios, Serlenga & Shin (2024, JBES)"
    return matrix diag_lm = `diagLM'

    scalar drop LMs pvs Ks Ns Ts
end


* ============================================================================ *
*  _xtft_haus -- Hausman-type test (FE vs CCE)                                 *
*  Kapetanios, Serlenga & Shin (2023, Empirical Economics 64:2611-2659)        *
* ============================================================================ *
capture program drop _xtft_haus
program define _xtft_haus, rclass
    syntax , depvar(varname) indepvars(varlist) id(varname) tm(varname)        ///
             touse(varname) [ cross(varlist) level(cilevel)                    ///
                              NOGraph graphsave(string) REPlace                ///
                              NOHeader COMPACT ]

    mata : _xtft_run_haus("`depvar'", "`indepvars'", "`id'", "`tm'", "`touse'")

    tempname bFE bCCE VFE VCCE
    scalar  Hs   = r(H)
    scalar  pvs  = r(pvalue)
    scalar  Ks   = r(K)
    scalar  Ns   = r(N)
    scalar  Ts   = r(T)
    matrix `bFE'  = r(beta_FE)
    matrix `bCCE' = r(beta_CCE)
    matrix `VFE'  = r(V_FE)
    matrix `VCCE' = r(V_CCE)

    if "`noheader'" == "" {
        _xtft_header "Hausman-type test of uncorrelated factor loadings"        ///
            "Kapetanios, Serlenga & Shin (2023, Empirical Economics 64:2611)"   ///
            "compares 2W-FE with CCE-MG (proxy for bias-corrected PC)"          ///
            `=scalar(Ns)' `=scalar(Ts)' `=scalar(Ks)'
    }
    di
    di as text "{hline 78}"
    di as text "  H0 : x_it uncorrelated with factor loadings gamma_i"
    di as text "       => 2W-FE remains consistent (use FE; CCE/PC also OK)"
    di as text "  H1 : x_it correlated with gamma_i  => use CCE / PC"
    di as text "{hline 78}"
    _xtft_one_stat "H (FE vs CCE)" `=scalar(Hs)' `=scalar(Ks)' `=scalar(pvs)' `level'

    if "`compact'" == "" {
        di
        di as text "  Coefficient comparison  (2W-FE  vs  CCE-MG):"
        _xtft_compare `bFE' `bCCE' `VFE' `VCCE' "`indepvars'"
    }

    if "`nograph'" == "" {
        _xtft_graph_haus `bFE' `bCCE' `VFE' `VCCE', indepvars(`indepvars')      ///
            graphsave(`graphsave') `replace'
    }

    return scalar H      = scalar(Hs)
    return scalar pvalue = scalar(pvs)
    return scalar df     = scalar(Ks)
    return scalar N      = scalar(Ns)
    return scalar T      = scalar(Ts)
    return scalar K      = scalar(Ks)
    return local  test   "Hausman-type"
    return local  ref    "Kapetanios, Serlenga & Shin (2023, Empirical Economics)"
    return matrix beta_FE  = `bFE'
    return matrix beta_CCE = `bCCE'
    return matrix V_FE     = `VFE'
    return matrix V_CCE    = `VCCE'

    scalar drop Hs pvs Ks Ns Ts
end


* ============================================================================ *
*  _xtft_joint -- HBFB joint test                                              *
*  Juodis & Reese (2026), Appendix A.2.2                                       *
* ============================================================================ *
capture program drop _xtft_joint
program define _xtft_joint, rclass
    syntax , depvar(varname) indepvars(varlist) id(varname) tm(varname)        ///
             touse(varname) [ cross(varlist) level(cilevel)                    ///
                              NOGraph graphsave(string) REPlace                ///
                              NOHeader COMPACT ]

    mata : _xtft_run_joint("`depvar'", "`indepvars'", "`id'", "`tm'", "`touse'")

    scalar  Js   = r(HBFB)
    scalar  pvs  = r(pvalue)
    scalar  Ks   = r(K)
    scalar  ms   = r(m)
    scalar  Ns   = r(N)
    scalar  Ts   = r(T)

    if "`noheader'" == "" {
        _xtft_header "HBFB joint test (heterogeneity OR factor-omission bias)" ///
            "Juodis & Reese (2026, J.Econometrics) Appendix A.2.2"              ///
            "stacks HB (Campello et al. 2019) and LM (Kapetanios et al. 2024)"  ///
            `=scalar(Ns)' `=scalar(Ts)' `=scalar(Ks)'
    }
    di
    di as text "{hline 78}"
    di as text "  H0 : 2W-FE has NEITHER heterogeneity bias NOR factor-omission bias"
    di as text "  H1 : at least one bias source is present"
    di as text "{hline 78}"
    _xtft_one_stat "HBFB" `=scalar(Js)' `=scalar(ms)' `=scalar(pvs)' `level'

    return scalar HBFB   = scalar(Js)
    return scalar pvalue = scalar(pvs)
    return scalar df     = scalar(ms)
    return scalar N      = scalar(Ns)
    return scalar T      = scalar(Ts)
    return scalar K      = scalar(Ks)
    return local  test   "HBFB joint"
    return local  ref    "Juodis & Reese (2026), App. A.2.2"

    scalar drop Js pvs Ks ms Ns Ts
end


* ============================================================================ *
*  _xtft_all -- run all four tests and produce a unified report               *
* ============================================================================ *
capture program drop _xtft_all
program define _xtft_all
    syntax , depvar(varname) indepvars(varlist) id(varname) tm(varname)        ///
             touse(varname) [ cross(varlist) npc(integer 1) level(cilevel)     ///
                              NOGraph graphsave(string) REPlace                ///
                              NOHeader ]

    if "`noheader'" == "" {
        _xtft_header "Full battery of specification tests for IE panels"        ///
            "Juodis & Reese (2026)  +  Kapetanios, Serlenga & Shin (2023, 2024)" ///
            "  +  Campello, Galvao & Juhl (2019)"                                ///
            . . .
    }

    tempname tbl
    matrix `tbl' = J(4, 4, .)
    matrix rownames `tbl' = "HB-CCE" "LM-X" "Hausman" "HBFB-joint"
    matrix colnames `tbl' = "Statistic" "df" "p-value" "Reject?"

    local alpha = (1 - `level'/100)

    /* pass-through graph control: only suppress per-test graphs if user      *
     * passed -nograph- to the -all- subcommand                               */
    local g_pass `nograph'

    /* 1. HB-CCE */
    di _newline as text _dup(78) "="
    di as text  "  [1/4]  HB-CCE  --  heterogeneity bias in pooled CCE"
    di as text _dup(78) "="
    _xtft_hb, depvar(`depvar') indepvars(`indepvars') id(`id') tm(`tm') ///
        touse(`touse') cross(`cross') level(`level')                    ///
        `g_pass' graphsave(`graphsave') `replace' noheader compact
    local HB    = r(HB)
    local HBp   = r(pvalue)
    local HBdf  = r(df)
    matrix `tbl'[1,1] = `HB'
    matrix `tbl'[1,2] = `HBdf'
    matrix `tbl'[1,3] = `HBp'
    matrix `tbl'[1,4] = (`HBp' < `alpha')

    tempname bI_all
    matrix `bI_all' = r(beta_i)

    /* 2. LM-X */
    di _newline as text _dup(78) "="
    di as text  "  [2/4]  LM-X  --  conditional indep. regressors vs loadings"
    di as text _dup(78) "="
    _xtft_lm, depvar(`depvar') indepvars(`indepvars') id(`id') tm(`tm') ///
        touse(`touse') npc(`npc') level(`level')                        ///
        `g_pass' graphsave(`graphsave') `replace' noheader compact
    local LM    = r(LM)
    local LMp   = r(pvalue)
    local LMdf  = r(df)
    matrix `tbl'[2,1] = `LM'
    matrix `tbl'[2,2] = `LMdf'
    matrix `tbl'[2,3] = `LMp'
    matrix `tbl'[2,4] = (`LMp' < `alpha')

    tempname diagLM_all
    matrix `diagLM_all' = r(diag_lm)

    /* 3. Hausman */
    di _newline as text _dup(78) "="
    di as text  "  [3/4]  Hausman-type  --  FE vs CCE coefficient gap"
    di as text _dup(78) "="
    _xtft_haus, depvar(`depvar') indepvars(`indepvars') id(`id') tm(`tm') ///
        touse(`touse') cross(`cross') level(`level')                      ///
        `g_pass' graphsave(`graphsave') `replace' noheader compact
    local H     = r(H)
    local Hp    = r(pvalue)
    local Hdf   = r(df)
    matrix `tbl'[3,1] = `H'
    matrix `tbl'[3,2] = `Hdf'
    matrix `tbl'[3,3] = `Hp'
    matrix `tbl'[3,4] = (`Hp' < `alpha')

    tempname bFE_all bCCE_all VFE_all VCCE_all
    matrix `bFE_all'  = r(beta_FE)
    matrix `bCCE_all' = r(beta_CCE)
    matrix `VFE_all'  = r(V_FE)
    matrix `VCCE_all' = r(V_CCE)

    /* 4. HBFB */
    di _newline as text _dup(78) "="
    di as text  "  [4/4]  HBFB joint  --  heterogeneity OR factor-omission bias"
    di as text _dup(78) "="
    _xtft_joint, depvar(`depvar') indepvars(`indepvars') id(`id') tm(`tm') ///
        touse(`touse') cross(`cross') level(`level') nograph noheader compact
    local J     = r(HBFB)
    local Jp    = r(pvalue)
    local Jdf   = r(df)
    matrix `tbl'[4,1] = `J'
    matrix `tbl'[4,2] = `Jdf'
    matrix `tbl'[4,3] = `Jp'
    matrix `tbl'[4,4] = (`Jp' < `alpha')

    /* unified summary */
    di _newline as text _dup(78) "="
    di as result _col(23) "S U M M A R Y    O F    T E S T S"
    di as text _dup(78) "="
    _xtft_summary_table `tbl' `level'

    /* policy recommendation */
    di _newline as text "{hline 78}"
    di as text  "  Decision rule (cf. Juodis & Reese 2026, Lessons 1-2)"
    di as text "{hline 78}"
    local rejHB  = (`HBp'  < `alpha')
    local rejLM  = (`LMp'  < `alpha')
    local rejH   = (`Hp'   < `alpha')
    local rejJ   = (`Jp'   < `alpha')

    if `rejHB' == 0 & `rejLM' == 0 & `rejH' == 0 & `rejJ' == 0 {
        di as result "  ==> No bias detected"
        di as text   "      Two-way FE is consistent. Safe to use OLS-FE."
    }
    else if `rejHB' == 0 & `rejLM' == 1 {
        di as result "  ==> Factor-omission bias only (slopes appear homogeneous)"
        di as text   "      Use CCEP (or CCE-MG) with cluster-robust SE."
    }
    else if `rejHB' == 1 & `rejLM' == 0 {
        di as result "  ==> Heterogeneity bias only (factors properly captured)"
        di as text   "      Use CCE-MG (mean-group) rather than pooled CCEP."
    }
    else if `rejHB' == 1 & `rejLM' == 1 {
        di as result "  ==> Both heterogeneity AND factor-omission bias"
        di as text   "      Use CCE-MG, with HPJ correction in dynamic settings."
    }
    else {
        di as result "  ==> Mixed evidence - inspect individual test results above"
    }
    di as text "{hline 78}"

    if "`nograph'" == "" {
        _xtft_graph_summary `tbl' `bI_all' `bFE_all' `bCCE_all',                ///
            indepvars(`indepvars') graphsave(`graphsave') `replace' level(`level')

        /* combine all four named graphs into one window so none is "lost"  */
        capture graph combine xtft_hb xtft_lm xtft_haus xtft_summary,          ///
            cols(2) iscale(0.7)                                                 ///
            title("xtfactortest -- all specification tests", size(medium))      ///
            note("xtfactortest v1.0", size(vsmall))                             ///
            graphregion(color(white)) scheme(s2color)                           ///
            name(xtft_all, replace)
        if !_rc {
            di
            di as text "  Individual graphs preserved in memory."
            di as text "    " as input "graph display xtft_hb"      as text "    -- HB-CCE histograms"
            di as text "    " as input "graph display xtft_lm"      as text "    -- LM-X scatter diagnostic"
            di as text "    " as input "graph display xtft_haus"    as text "    -- FE vs CCE coefficient plot"
            di as text "    " as input "graph display xtft_summary" as text "    -- summary forest plot"
            di as text "    " as input "graph display xtft_all"     as text "    -- 2x2 combined view"
            if "`graphsave'" != "" {
                cap graph export `"`graphsave'_all.png"', as(png) `replace' width(2000)
                if !_rc di as text "  graph saved -> " as input `"`graphsave'_all.png"'
            }
        }
    }
end


* ============================================================================ *
*  Pretty-print helpers                                                        *
* ============================================================================ *
capture program drop _xtft_header
program define _xtft_header
    args title ref1 ref2 N T K
    di
    di as text "{hline 78}"
    di as text " xtfactortest  --  v1.0"
    di as text "{hline 78}"
    di as result "  `title'"
    di as text   "    " as smcl "`ref1'"
    if `"`ref2'"' != "" {
        di as text   "    `ref2'"
    }
    if "`N'" != "." {
        di
        di as text "  Panel:  N = " as result `N' as text ",   T = " as result `T' ///
            as text ",   K = " as result `K' as text " regressor(s)"
    }
end

capture program drop _xtft_one_stat
program define _xtft_one_stat
    args name stat df pval level
    local alpha = 1 - `level'/100
    di
    di as text "  Test                Statistic       df        p-value     Decision (alpha=" %4.2f `alpha' ")"
    di as text "  {hline 17}{hline 11}{hline 9}{hline 12}{hline 25}"
    if `pval' < `alpha' {
        di as text "  " %-17s "`name'" as result %10.4f `stat' "    " %4.0f `df' "      " %9.4f `pval'  "    " as error "REJECT  H0"
    }
    else {
        di as text "  " %-17s "`name'" as result %10.4f `stat' "    " %4.0f `df' "      " %9.4f `pval'  "    " as result "Do not reject"
    }
end

capture program drop _xtft_coef_table
program define _xtft_coef_table
    args bmat semat varnames level
    local K = colsof(`bmat')
    local zcrit = invnormal(1 - (1-`level'/100)/2)
    di as text "  {hline 76}"
    di as text "  Variable             Coef.       Std.Err.        z      P>|z|     [`level'% CI]"
    di as text "  {hline 76}"
    forvalues k = 1/`K' {
        local vn : word `k' of `varnames'
        local b   = `bmat'[1,`k']
        local se  = `semat'[1,`k']
        local z   = `b' / `se'
        local p   = 2*(1 - normal(abs(`z')))
        local lo  = `b' - `zcrit'*`se'
        local hi  = `b' + `zcrit'*`se'
        di as result "  " %-18s "`vn'" %10.4f `b' "    " %10.4f `se' "  " %7.2f `z' "  " %7.3f `p' "  [" %7.3f `lo' " , " %7.3f `hi' "]"
    }
    di as text "  {hline 76}"
end

capture program drop _xtft_compare
program define _xtft_compare
    args b1 b2 V1 V2 varnames
    local K = colsof(`b1')
    di as text "  {hline 78}"
    di as text "  Variable           2W-FE  (SE)              CCE-MG  (SE)         Difference"
    di as text "  {hline 78}"
    forvalues k = 1/`K' {
        local vn : word `k' of `varnames'
        local b1k = `b1'[1,`k']
        local b2k = `b2'[1,`k']
        local s1k = sqrt(`V1'[`k',`k'])
        local s2k = sqrt(`V2'[`k',`k'])
        local d   = `b1k' - `b2k'
        di as result "  " %-15s "`vn'" "  " %9.4f `b1k' "  (" %7.4f `s1k' ")" ///
            "      " %9.4f `b2k' "  (" %7.4f `s2k' ")" "    " %9.4f `d'
    }
    di as text "  {hline 78}"
end

capture program drop _xtft_summary_table
program define _xtft_summary_table
    args tbl level
    local alpha = 1 - `level'/100
    di as text "  {hline 76}"
    di as text "  Test                  Statistic      df      p-value      Decision (a=" %4.2f `alpha' ")"
    di as text "  {hline 76}"
    local R = rowsof(`tbl')
    local rn : rowfullnames `tbl'
    forvalues r = 1/`R' {
        local nm : word `r' of `rn'
        local s  = `tbl'[`r',1]
        local d  = `tbl'[`r',2]
        local p  = `tbl'[`r',3]
        local rj = `tbl'[`r',4]
        if `rj' == 1 {
            di as text "  " %-18s "`nm'" "  " as result %10.4f `s' "   " %4.0f `d' "    " %9.4f `p' "      " as error "REJECT H0"
        }
        else {
            di as text "  " %-18s "`nm'" "  " as result %10.4f `s' "   " %4.0f `d' "    " %9.4f `p' "      " as result "do not reject"
        }
    }
    di as text "  {hline 76}"
end


* ============================================================================ *
*  Visualisation routines                                                      *
* ============================================================================ *
capture program drop _xtft_graph_hb
program define _xtft_graph_hb
    syntax anything(name=BI), indepvars(varlist) [ graphsave(string) REPlace ]
    local K : word count `indepvars'
    local NN = rowsof(`BI')
    if `NN' == 0 exit

    preserve
        clear
        qui set obs `NN'
        forvalues k = 1/`K' {
            local vn : word `k' of `indepvars'
            qui gen double beta_`k' = .
            forvalues i = 1/`NN' {
                qui replace beta_`k' = `BI'[`i',`k'] in `i'
            }
            label var beta_`k' "{&beta}_i (`vn')"
        }
        local grlist
        forvalues k = 1/`K' {
            local vn : word `k' of `indepvars'
            qui sum beta_`k', detail
            local med   = r(p50)
            local mean  = r(mean)
            local gname _xtfthbg`k'
            twoway (histogram beta_`k' , bin(30) fcolor(navy%50) lcolor(navy%70))    ///
                   (kdensity  beta_`k' , lcolor(maroon) lwidth(medthick))             ///
                , xline(`mean', lcolor(red)   lpattern(solid)   lwidth(medthick))     ///
                  xline(`med',  lcolor(black) lpattern(dash))                         ///
                  legend(order(1 "histogram" 2 "kernel density")                      ///
                         ring(0) pos(2) cols(1) region(lcolor(white)))                ///
                  title("Distribution of {&beta}_i  --  `vn'", size(medium))          ///
                  subtitle("CCE-MG (red solid) and median (dashed)", size(small))     ///
                  xtitle("{&beta}_i", size(small)) ytitle("Density", size(small))     ///
                  graphregion(color(white)) plotregion(color(white))                  ///
                  scheme(s2color) name(`gname', replace) nodraw
            local grlist `grlist' `gname'
        }
        local ncol = ceil(sqrt(`K'))
        graph combine `grlist', col(`ncol') iscale(0.85)                              ///
              title("HB-CCE test: distribution of individual CCE slopes", size(medium)) ///
              subtitle("Juodis & Reese (2026, J.Econometrics), Lesson 2", size(small)) ///
              note("xtfactortest v1.0", size(vsmall))                                  ///
              graphregion(color(white)) scheme(s2color)                                 ///
              name(xtft_hb, replace)
        if "`graphsave'" != "" {
            cap graph export `"`graphsave'_hb.png"', as(png) `replace' width(1600)
            if !_rc di as text "  graph saved -> " as input `"`graphsave'_hb.png"'
        }
    restore
end

capture program drop _xtft_graph_lm
program define _xtft_graph_lm
    syntax anything(name=DIAG), indepvars(varlist) [ graphsave(string) REPlace ]
    local NN = rowsof(`DIAG')
    if `NN' == 0 exit

    preserve
        clear
        qui set obs `NN'
        qui gen double pcproj = .
        qui gen double residm = .
        forvalues i = 1/`NN' {
            qui replace pcproj = `DIAG'[`i',1] in `i'
            qui replace residm = `DIAG'[`i',2] in `i'
        }
        label var pcproj "Projection F_X' x_i  (first PC)"
        label var residm "FE residual (mean)"
        twoway (scatter residm pcproj, mcolor(navy%70) msymbol(O) msize(small))        ///
               (lfit    residm pcproj, lcolor(red) lwidth(medthick))                    ///
            , title("LM-X diagnostic", size(medium))                                    ///
              subtitle("FE residuals against the first PC of regressors", size(small))  ///
              xtitle("Projection F_X' x_i", size(small))                                ///
              ytitle("FE residual u_hat_i", size(small))                                ///
              legend(order(2 "OLS fit") ring(0) pos(2) region(lcolor(white)))           ///
              note("Kapetanios, Serlenga & Shin (2024, JBES)", size(vsmall))            ///
              graphregion(color(white)) plotregion(color(white)) scheme(s2color)        ///
              name(xtft_lm, replace)
        if "`graphsave'" != "" {
            cap graph export `"`graphsave'_lm.png"', as(png) `replace' width(1600)
            if !_rc di as text "  graph saved -> " as input `"`graphsave'_lm.png"'
        }
    restore
end

capture program drop _xtft_graph_haus
program define _xtft_graph_haus
    syntax anything(name=mats), indepvars(varlist) [ graphsave(string) REPlace ]
    tokenize `mats'
    local bFE  `1'
    local bCCE `2'
    local VFE  `3'
    local VCCE `4'
    local K = colsof(`bFE')

    preserve
        clear
        qui set obs `K'
        qui gen str20 vname = ""
        qui gen double bFE  = .
        qui gen double bCCE = .
        qui gen double seFE = .
        qui gen double seCCE = .
        qui gen kpos = _n
        forvalues k = 1/`K' {
            local vn : word `k' of `indepvars'
            qui replace vname = "`vn'"            in `k'
            qui replace bFE  = `bFE'[1,`k']       in `k'
            qui replace bCCE = `bCCE'[1,`k']      in `k'
            qui replace seFE  = sqrt(`VFE'[`k',`k'])  in `k'
            qui replace seCCE = sqrt(`VCCE'[`k',`k']) in `k'
        }
        qui gen loFE  = bFE  - 1.96*seFE
        qui gen hiFE  = bFE  + 1.96*seFE
        qui gen loCCE = bCCE - 1.96*seCCE
        qui gen hiCCE = bCCE + 1.96*seCCE
        qui gen kFE  = kpos - 0.15
        qui gen kCCE = kpos + 0.15

        local ylabs
        forvalues k = 1/`K' {
            local vn : word `k' of `indepvars'
            local ylabs `ylabs' `k' "`vn'"
        }
        twoway (rcap loFE  hiFE  kFE,  horizontal lcolor(navy))                  ///
               (scatter kFE  bFE  , msymbol(O) mcolor(navy)   msize(medlarge))    ///
               (rcap loCCE hiCCE kCCE, horizontal lcolor(maroon))                  ///
               (scatter kCCE bCCE , msymbol(D) mcolor(maroon) msize(medlarge))    ///
            , ylabel(`ylabs', valuelabel angle(0))                                ///
              ytitle("") xtitle("Coefficient estimate (95% CI)", size(small))     ///
              title("FE vs CCE coefficients (Hausman-type test)", size(medium))   ///
              subtitle("Kapetanios, Serlenga & Shin (2023, Emp.Econ. 64:2611)", size(small)) ///
              legend(order(2 "2W-FE" 4 "CCE-MG") ring(0) pos(2) region(lcolor(white))) ///
              note("Wide gap between FE and CCE markers => correlated factor loadings", size(vsmall)) ///
              graphregion(color(white)) plotregion(color(white)) scheme(s2color)  ///
              name(xtft_haus, replace)
        if "`graphsave'" != "" {
            cap graph export `"`graphsave'_haus.png"', as(png) `replace' width(1600)
            if !_rc di as text "  graph saved -> " as input `"`graphsave'_haus.png"'
        }
    restore
end

capture program drop _xtft_graph_summary
program define _xtft_graph_summary
    syntax anything(name=mats), indepvars(varlist) [ level(cilevel) ///
        graphsave(string) REPlace ]
    tokenize `mats'
    local tbl     `1'
    local bI      `2'
    local bFE     `3'
    local bCCE    `4'

    if "`level'" == "" local level 95
    local alpha = 1 - `level'/100

    preserve
        clear
        qui set obs 4
        qui gen str20 test = ""
        qui gen double stat = .
        qui gen double df   = .
        qui gen double pval = .
        qui gen double crit = .
        qui gen double rej  = .
        local labs `" "HB-CCE" "LM-X" "Hausman" "HBFB joint" "'
        forvalues r = 1/4 {
            local nm : word `r' of `labs'
            qui replace test = "`nm'"          in `r'
            qui replace stat = `tbl'[`r',1]    in `r'
            qui replace df   = `tbl'[`r',2]    in `r'
            qui replace pval = `tbl'[`r',3]    in `r'
            qui replace crit = invchi2(`tbl'[`r',2], 1-`alpha') in `r'
            qui replace rej  = `tbl'[`r',4]    in `r'
        }
        qui gen pos = _n
        local astr : di %4.2f `alpha'
        twoway (bar stat pos , horizontal barwidth(0.55) fcolor(navy%55) lcolor(navy)) ///
               (scatter pos crit , msymbol(X) mcolor(red) msize(large))                 ///
            , ylabel(1 "HB-CCE" 2 "LM-X" 3 "Hausman" 4 "HBFB joint", angle(0))          ///
              ytitle("") xtitle("Test statistic", size(small))                          ///
              title("Specification tests for IE panels", size(medium))                  ///
              subtitle(`"Bars = statistic; red X = chi^2 critical value (a=`astr')"', size(small)) ///
              legend(order(1 "Statistic" 2 "Critical value") ring(0) pos(2))            ///
              note("xtfactortest v1.0", size(vsmall))                                  ///
              graphregion(color(white)) plotregion(color(white)) scheme(s2color)        ///
              name(xtft_summary, replace)
        if "`graphsave'" != "" {
            cap graph export `"`graphsave'_summary.png"', as(png) `replace' width(1600)
            if !_rc di as text "  graph saved -> " as input `"`graphsave'_summary.png"'
        }
    restore
end


* ============================================================================ *
*  Mata library  (top-level: executed once when xtfactortest.ado loads)        *
* ============================================================================ *

mata:
mata clear

real scalar _xtft_version()
{
    return(1.0)
}

/* ------------------------------------------------------------------ */
/*  Reshape long data (sorted by id, then t) into                     */
/*    Yp : T x N   ;   Xp : T x (N*K)  (regressors stacked unit-wise) */
/* ------------------------------------------------------------------ */
void _xtft_to_panels(string scalar yname, string scalar xnames,
                     string scalar idname, string scalar tmname,
                     string scalar touse,
                     real matrix Yp, real matrix Xp,
                     real scalar N, real scalar T, real scalar K)
{
    real matrix Y, X, ID, TM
    real colvector ids, idx
    real scalar i

    st_view(Y , ., yname,  touse)
    st_view(X , ., xnames, touse)
    st_view(ID, ., idname, touse)
    st_view(TM, ., tmname, touse)

    ids = uniqrows(ID)
    N   = rows(ids)
    T   = rows(uniqrows(TM))
    K   = cols(X)

    Yp = J(T, N, .)
    Xp = J(T, N*K, .)
    for (i = 1; i <= N; i++) {
        idx = selectindex(ID :== ids[i])
        Yp[., i] = Y[idx, .]
        Xp[., (i-1)*K + 1 .. i*K] = X[idx, .]
    }
}

/* ------------------------------------------------------------------ */
/*  Cross-sectional averages bar Z = (bar y, bar x_1, ..., bar x_K)    */
/* ------------------------------------------------------------------ */
real matrix _xtft_Fhat(real matrix Yp, real matrix Xp,
                       real scalar N, real scalar T, real scalar K)
{
    real colvector ybar
    real matrix    xbar
    real scalar    k, i

    ybar = rowsum(Yp) :/ N
    xbar = J(T, K, 0)
    for (k = 1; k <= K; k++) {
        for (i = 1; i <= N; i++) {
            xbar[., k] = xbar[., k] + Xp[., (i-1)*K + k]
        }
    }
    xbar = xbar :/ N
    return((ybar, xbar))
}

/* ------------------------------------------------------------------ */
/*  Residual maker M = I - F (F'F)^-1 F'                              */
/* ------------------------------------------------------------------ */
real matrix _xtft_M(real matrix F)
{
    return(I(rows(F)) - F * invsym(F' * F) * F')
}

/* ------------------------------------------------------------------ */
/*  Two-way within transformation of a T x N matrix Y                  */
/* ------------------------------------------------------------------ */
real matrix _xtft_2w_y(real matrix Yp)
{
    real scalar Tn, Nn
    real colvector yhat_t
    real rowvector yhat_i
    real scalar    ygrand

    Tn = rows(Yp)
    Nn = cols(Yp)
    yhat_t = rowsum(Yp) :/ Nn          // T x 1
    yhat_i = colsum(Yp) :/ Tn          // 1 x N
    ygrand = sum(Yp) / (Nn * Tn)
    return( Yp - yhat_t * J(1, Nn, 1) - J(Tn, 1, 1) * yhat_i + ygrand * J(Tn, Nn, 1) )
}

/* ------------------------------------------------------------------ */
/*  Two-way within of regressor block: returns Xt  (T x NK)            */
/* ------------------------------------------------------------------ */
real matrix _xtft_2w_x(real matrix Xp, real scalar N, real scalar T, real scalar K)
{
    real matrix Xt, Xk
    real scalar k, i
    real colvector xhat_t
    real rowvector xhat_i
    real scalar    xgrand

    Xt = J(T, N*K, .)
    for (k = 1; k <= K; k++) {
        Xk = J(T, N, .)
        for (i = 1; i <= N; i++) Xk[., i] = Xp[., (i-1)*K + k]
        xhat_t = rowsum(Xk) :/ N
        xhat_i = colsum(Xk) :/ T
        xgrand = sum(Xk) / (N * T)
        Xk = Xk - xhat_t * J(1, N, 1) - J(T, 1, 1) * xhat_i + xgrand * J(T, N, 1)
        for (i = 1; i <= N; i++) Xt[., (i-1)*K + k] = Xk[., i]
    }
    return(Xt)
}

/* ------------------------------------------------------------------ */
/*  HB-CCE  (Juodis-Reese 2026, Lesson 2)                              */
/* ------------------------------------------------------------------ */
void _xtft_run_hb(string scalar yname, string scalar xnames,
                  string scalar idname, string scalar tmname, string scalar touse)
{
    real matrix Yp, Xp, F, M
    real scalar N, T, K, i
    real matrix Xi, yi, XMX_i, betas, beta_MG, XMX_all
    real matrix XMX_avg, dHB_i, dHB_avg, deltas, Var, VarMG
    real scalar HB, pval

    _xtft_to_panels(yname, xnames, idname, tmname, touse, Yp=., Xp=., N=., T=., K=.)
    F = _xtft_Fhat(Yp, Xp, N, T, K)
    M = _xtft_M(F)

    betas   = J(K, N, .)
    XMX_all = J(K, K*N, .)
    XMX_avg = J(K, K, 0)
    for (i = 1; i <= N; i++) {
        Xi    = Xp[., (i-1)*K + 1 .. i*K]
        yi    = Yp[., i]
        XMX_i = Xi' * M * Xi
        betas[., i] = invsym(XMX_i) * Xi' * M * yi
        XMX_all[., (i-1)*K + 1 .. i*K] = XMX_i
        XMX_avg = XMX_avg + XMX_i
    }
    XMX_avg = XMX_avg :/ N
    beta_MG = rowsum(betas) :/ N

    deltas  = J(K, N, .)
    dHB_avg = J(K, 1, 0)
    for (i = 1; i <= N; i++) {
        XMX_i = XMX_all[., (i-1)*K + 1 .. i*K]
        dHB_i = (XMX_i - XMX_avg) * (betas[., i] - beta_MG)
        deltas[., i] = dHB_i
        dHB_avg = dHB_avg + dHB_i
    }
    dHB_avg = dHB_avg :/ N

    Var = J(K, K, 0)
    for (i = 1; i <= N; i++) Var = Var + deltas[., i] * deltas[., i]'
    Var = Var :/ (N * N)

    HB   = dHB_avg' * invsym(Var) * dHB_avg
    pval = chi2tail(K, HB)

    /* CCE-MG nonparametric variance (Pesaran 2006 / KSS V_NON) */
    VarMG = J(K, K, 0)
    for (i = 1; i <= N; i++) {
        VarMG = VarMG + (betas[., i] - beta_MG) * (betas[., i] - beta_MG)'
    }
    VarMG = VarMG :/ (N * (N - 1))

    st_numscalar("r(HB)"       , HB)
    st_numscalar("r(pvalue)"   , pval)
    st_numscalar("r(df)"       , K)
    st_numscalar("r(N)"        , N)
    st_numscalar("r(T)"        , T)
    st_numscalar("r(K)"        , K)
    st_matrix("r(beta_CCEMG)"  , beta_MG')
    st_matrix("r(Var_CCEMG)"   , VarMG)
    st_matrix("r(beta_i)"      , betas')
    st_matrix("r(delta_HB)"    , dHB_avg')
}

/* ------------------------------------------------------------------ */
/*  LM-X  (Kapetanios-Serlenga-Shin 2024, JBES)                        */
/*  Uses two-way within FE residuals and first r_pc PC(s) of           */
/*  regressors as instruments.                                          */
/* ------------------------------------------------------------------ */
void _xtft_run_lm(string scalar yname, string scalar xnames,
                  string scalar idname, string scalar tmname,
                  string scalar touse, real scalar r_pc)
{
    real matrix Yp, Xp, Yt, Xt
    real scalar N, T, K, i, npc
    real matrix Xi, yi, beta_FE_i, u_i, S, F_X, P_F, Xhat_i
    real matrix eigvec, eigval, score_i, sum_score, V, diag_lm
    real scalar LM, pval

    _xtft_to_panels(yname, xnames, idname, tmname, touse, Yp=., Xp=., N=., T=., K=.)
    Yt = _xtft_2w_y(Yp)
    Xt = _xtft_2w_x(Xp, N, T, K)

    /* leading PC(s) of regressors: eigen-decomp of S = (NT)^-1 sum_i Xt_i Xt_i'  */
    S = J(T, T, 0)
    for (i = 1; i <= N; i++) {
        Xi = Xt[., (i-1)*K + 1 .. i*K]
        S = S + Xi * Xi'
    }
    S = S :/ (N * T)
    /* symeigensystem returns eigenvalues in descending order; ensure symmetry */
    S = (S + S') :/ 2
    symeigensystem(S, eigvec=., eigval=.)
    npc   = min((r_pc, T))
    F_X   = sqrt(T) * eigvec[., 1..npc]
    P_F   = F_X * invsym(F_X' * F_X) * F_X'

    /* score = N^-1/2 sum_i  Xhat_i' u_i / T   ;   V = N^-1 sum  (Xhat_i' u_i)(.)' / T^2 */
    sum_score = J(K, 1, 0)
    V         = J(K, K, 0)
    diag_lm   = J(N, 2, .)
    for (i = 1; i <= N; i++) {
        Xi        = Xt[., (i-1)*K + 1 .. i*K]
        yi        = Yt[., i]
        beta_FE_i = invsym(Xi' * Xi) * Xi' * yi
        u_i       = yi - Xi * beta_FE_i
        Xhat_i    = P_F * Xi
        score_i   = Xhat_i' * u_i :/ T
        sum_score = sum_score + score_i
        V         = V + score_i * score_i'
        diag_lm[i, 1] = mean(F_X[., 1] :* Xi[., 1])
        diag_lm[i, 2] = mean(u_i)
    }
    sum_score = sum_score :/ sqrt(N)
    V         = V :/ N

    LM   = sum_score' * invsym(V) * sum_score
    pval = chi2tail(K, LM)

    st_numscalar("r(LM)"      , LM)
    st_numscalar("r(pvalue)"  , pval)
    st_numscalar("r(df)"      , K)
    st_numscalar("r(N)"       , N)
    st_numscalar("r(T)"       , T)
    st_numscalar("r(K)"       , K)
    st_matrix("r(diag_lm)"    , diag_lm)
}

/* ------------------------------------------------------------------ */
/*  Hausman-type (KSS 2023, Empirical Economics)                       */
/*  H = (beta_FE - beta_CCE_MG)' (V_FE + V_CCE)^-1 (.)                  */
/* ------------------------------------------------------------------ */
void _xtft_run_haus(string scalar yname, string scalar xnames,
                    string scalar idname, string scalar tmname, string scalar touse)
{
    real matrix Yp, Xp, F, M, Yt, Xt
    real scalar N, T, K, i
    real matrix Xi, yi, betas_FE, betas_CCE
    real matrix beta_FE, beta_CCE_MG, V_FE, V_CCE, diff, V, H
    real scalar pval

    _xtft_to_panels(yname, xnames, idname, tmname, touse, Yp=., Xp=., N=., T=., K=.)
    F  = _xtft_Fhat(Yp, Xp, N, T, K)
    M  = _xtft_M(F)
    Yt = _xtft_2w_y(Yp)
    Xt = _xtft_2w_x(Xp, N, T, K)

    betas_FE  = J(K, N, .)
    betas_CCE = J(K, N, .)
    for (i = 1; i <= N; i++) {
        Xi = Xt[., (i-1)*K + 1 .. i*K]
        yi = Yt[., i]
        betas_FE[., i]  = invsym(Xi' * Xi) * Xi' * yi
        Xi = Xp[., (i-1)*K + 1 .. i*K]
        yi = Yp[., i]
        betas_CCE[., i] = invsym(Xi' * M * Xi) * Xi' * M * yi
    }
    beta_FE     = rowsum(betas_FE)  :/ N
    beta_CCE_MG = rowsum(betas_CCE) :/ N

    /* KSS 2023 nonparametric variance of the FE-CCE difference        */
    /* Var(b_FE - b_CCE) = V_FE + V_CCE - 2*Cov(b_FE, b_CCE)            */
    real matrix Cov
    V_FE  = J(K, K, 0)
    V_CCE = J(K, K, 0)
    Cov   = J(K, K, 0)
    for (i = 1; i <= N; i++) {
        V_FE  = V_FE  + (betas_FE[., i]  - beta_FE)     * (betas_FE[., i]  - beta_FE)'
        V_CCE = V_CCE + (betas_CCE[., i] - beta_CCE_MG) * (betas_CCE[., i] - beta_CCE_MG)'
        Cov   = Cov   + (betas_FE[., i]  - beta_FE)     * (betas_CCE[., i] - beta_CCE_MG)'
    }
    V_FE  = V_FE  :/ (N * (N - 1))
    V_CCE = V_CCE :/ (N * (N - 1))
    Cov   = Cov   :/ (N * (N - 1))

    diff = beta_FE - beta_CCE_MG
    V    = V_FE + V_CCE - Cov - Cov'
    H    = diff' * invsym(V) * diff
    pval = chi2tail(K, H)

    st_numscalar("r(H)"      , H)
    st_numscalar("r(pvalue)" , pval)
    st_numscalar("r(df)"     , K)
    st_numscalar("r(N)"      , N)
    st_numscalar("r(T)"      , T)
    st_numscalar("r(K)"      , K)
    st_matrix("r(beta_FE)"   , beta_FE')
    st_matrix("r(beta_CCE)"  , beta_CCE_MG')
    st_matrix("r(V_FE)"      , V_FE)
    st_matrix("r(V_CCE)"     , V_CCE)
}

/* ------------------------------------------------------------------ */
/*  HBFB joint  (Juodis-Reese 2026, App. A.2.2)                        */
/*  Stacks Campello HB and KSS LM-style factor-omission moments.       */
/* ------------------------------------------------------------------ */
void _xtft_run_joint(string scalar yname, string scalar xnames,
                     string scalar idname, string scalar tmname, string scalar touse)
{
    real matrix Yp, Xp, F, M, Yt, Xt
    real scalar N, T, K, i, m
    real matrix Xi, yi, Xit, yit, betas_CCE, beta_MG, XMX_all, XMX_avg, XMX_i
    real matrix dHB_i, dFB_i, d_i, deltas, sum_d, delta, V
    real matrix S, eigvec, eigval, F_X, P_F, beta_FE_i, u_FE_i, Xhat_i
    real scalar stat, pval

    _xtft_to_panels(yname, xnames, idname, tmname, touse, Yp=., Xp=., N=., T=., K=.)
    F  = _xtft_Fhat(Yp, Xp, N, T, K)
    M  = _xtft_M(F)
    Yt = _xtft_2w_y(Yp)
    Xt = _xtft_2w_x(Xp, N, T, K)

    /* CCE-MG  +  cache X_i' M X_i  */
    betas_CCE = J(K, N, .)
    XMX_all   = J(K, K*N, .)
    XMX_avg   = J(K, K, 0)
    for (i = 1; i <= N; i++) {
        Xi    = Xp[., (i-1)*K + 1 .. i*K]
        yi    = Yp[., i]
        XMX_i = Xi' * M * Xi
        betas_CCE[., i] = invsym(XMX_i) * Xi' * M * yi
        XMX_all[., (i-1)*K + 1 .. i*K] = XMX_i
        XMX_avg = XMX_avg + XMX_i
    }
    XMX_avg = XMX_avg :/ N
    beta_MG = rowsum(betas_CCE) :/ N

    /* first PC of regressors (within 2-way) */
    S = J(T, T, 0)
    for (i = 1; i <= N; i++) {
        Xit = Xt[., (i-1)*K + 1 .. i*K]
        S = S + Xit * Xit'
    }
    S = S :/ (N * T)
    S = (S + S') :/ 2
    symeigensystem(S, eigvec=., eigval=.)
    F_X = sqrt(T) * eigvec[., 1]
    P_F = F_X * invsym(F_X' * F_X) * F_X'

    /* stack [dHB_i ; dFB_i]    each K x 1   =>  d_i  is 2K x 1   */
    sum_d  = J(2*K, 1, 0)
    deltas = J(2*K, N, .)
    for (i = 1; i <= N; i++) {
        XMX_i = XMX_all[., (i-1)*K + 1 .. i*K]
        dHB_i = (XMX_i - XMX_avg) * (betas_CCE[., i] - beta_MG)

        Xit       = Xt[., (i-1)*K + 1 .. i*K]
        yit       = Yt[., i]
        beta_FE_i = invsym(Xit' * Xit) * Xit' * yit
        u_FE_i    = yit - Xit * beta_FE_i
        Xhat_i    = P_F * Xit
        dFB_i     = Xhat_i' * u_FE_i :/ T

        d_i           = dHB_i \ dFB_i
        deltas[., i]  = d_i
        sum_d         = sum_d + d_i
    }
    delta = sum_d :/ N
    V     = J(2*K, 2*K, 0)
    for (i = 1; i <= N; i++) V = V + deltas[., i] * deltas[., i]'
    V     = V :/ (N * N)
    m     = 2 * K
    stat  = delta' * invsym(V) * delta
    pval  = chi2tail(m, stat)

    st_numscalar("r(HBFB)"   , stat)
    st_numscalar("r(pvalue)" , pval)
    st_numscalar("r(df)"     , m)
    st_numscalar("r(m)"      , m)
    st_numscalar("r(N)"      , N)
    st_numscalar("r(T)"      , T)
    st_numscalar("r(K)"      , K)
}

end /* mata */
