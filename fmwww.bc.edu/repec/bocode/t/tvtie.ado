*! tvtie 1.2.0 13sep2026
*! Levent Kutlu
*! Copyright (C) 2026 Levent Kutlu. GNU GPL v3; see tvtie_license.txt.
program define tvtie, eclass
    version 16.0
    if replay() {
        if "`e(cmd)'" != "tvtie" error 301
        syntax [, Level(cilevel)]
        _tvtie_display, level(`level')
        exit
    }
    local cmdline `"tvtie `0'"'
    syntax varlist(min=1 numeric fv) [if] [in] [, ///
        ID(varname numeric) TIME(varname numeric) Uhet(varlist numeric) ///
        HETerogeneity(varlist numeric) TREND(integer -1) NOHET NOHETCONStant NOCONStant ///
        COST PRODuction ENdogenous(varlist numeric) Instruments(varlist numeric) ///
        ENDOFunctions(varlist numeric) RFVars(varlist numeric) ///
        DISTribution(string) VCE(string) STARTS(integer 8) SEED(integer 190119) ///
        ITERate(integer 500) TOLerance(real 0.0000001) FROM(name) ///
        NOLOG DROPSHORT Level(cilevel)]
    gettoken depvar indepvars : varlist
    confirm numeric variable `depvar'
    local automatic_functions ""
    if "`indepvars'"!="" {
        local enopt ""
        if "`endogenous'"!="" local enopt "endogenous(`endogenous')"
        _tvtie_expand `indepvars', `enopt'
        local indepvars "`r(terms)'"
        local automatic_functions "`r(functions)'"
    }
    local declared_functions "`endofunctions'"
    local endofunctions `endofunctions' `automatic_functions'
    local endofunctions : list uniq endofunctions
    if "`cost'" != "" & "`production'" != "" {
        di as error "Specify either cost or production, not both."
        exit 198
    }
    if "`id'" == "" {
        capture quietly xtset
        if _rc {
            di as error "Use xtset or specify id() and, for time trends, time()."
            exit 459
        }
        local id "`r(panelvar)'"
        if "`time'" == "" local time "`r(timevar)'"
    }
    if "`id'" == "" {
        di as error "A numeric panel identifier is required."
        exit 459
    }
    if "`nohet'" != "" {
        if "`heterogeneity'`nohetconstant'" != "" | `trend' != -1 {
            di as error "nohet may not be combined with heterogeneity(), trend(), or nohetconstant."
            exit 198
        }
        local trend 0
    }
    else {
        if "`heterogeneity'" != "" {
            if `trend' != -1 {
                di as error "Choose heterogeneity() or trend(), not both."
                exit 198
            }
            local trend 0
        }
        else if `trend' == -1 local trend 2
    }
    if "`nohetconstant'" != "" & "`heterogeneity'" == "" & `trend' == 0 {
        di as error "trend(0) nohetconstant leaves an empty heterogeneity basis; specify nohet instead."
        exit 198
    }
    if `trend' < 0 | `trend' > 8 {
        di as error "trend() must be an integer from 0 through 8; use heterogeneity() for other bases."
        exit 198
    }
    if `trend' > 0 & "`time'" == "" {
        capture quietly xtset
        if !_rc local time "`r(timevar)'"
        if "`time'" == "" {
            di as error "Specify time() or xtset a time variable, or use trend(0)."
            exit 459
        }
    }
    local distribution = lower(strtrim("`distribution'"))
    if "`distribution'" == "" local distribution "hnormal"
    if !inlist("`distribution'", "hnormal", "tnormal") {
        di as error "distribution() must be hnormal or tnormal."
        exit 198
    }
    if `starts' < 1 | `starts' > 100 | `iterate' < 1 | `iterate' > 100000 {
        di as error "Use 1-100 starts and 1-100000 iterations."
        exit 198
    }
    if `tolerance' <= 0 | `tolerance' >= .001 {
        di as error "tolerance() must be positive and smaller than .001."
        exit 198
    }
    if `seed' < 0 | `seed' > 2147483647 {
        di as error "seed() must be an integer from 0 through 2147483647."
        exit 198
    }
    if "`from'" != "" confirm matrix `from'
    local vcespec = strtrim("`vce'" )
    gettoken vcetype clustvar : vcespec
    local vcetype = lower("`vcetype'")
    local clustvar = strtrim("`clustvar'")
    if "`vcetype'" == "" local vcetype "oim"
    if "`vcetype'" == "cluster" {
        local nc : word count `clustvar'
        if `nc' != 1 {
            di as error "vce(cluster) requires one numeric cluster variable."
            exit 198
        }
        confirm numeric variable `clustvar'
    }
    else if "`clustvar'" != "" {
        di as error "Unexpected argument in vce()."
        exit 198
    }
    if !inlist("`vcetype'", "oim", "robust", "cluster") {
        di as error "Use vce(oim), vce(robust), or vce(cluster clustvar)."
        exit 198
    }
    local both `indepvars' `uhet'
    local both : list uniq both
    local endogenous : list uniq endogenous
    local instruments : list uniq instruments
    local endofunctions : list uniq endofunctions
    local zvars ""
    if "`endogenous'" == "" {
        if "`instruments'`endofunctions'`rfvars'" != "" {
            di as error "instruments(), endofunctions(), and rfvars() require endogenous()."
            exit 198
        }
    }
    else {
        if "`instruments'" == "" {
            di as error "Specify excluded instruments in instruments()."
            exit 198
        }
        local p : word count `endogenous'
        local nz : word count `instruments'
        if `nz' < `p' {
            di as error "This implementation requires at least one distinct excluded instrument per primitive endogenous variable."
            exit 481
        }
        local bad : list endofunctions - both
        if "`bad'" != "" {
            di as error "Every endofunctions() variable must appear in the frontier or uhet(): `bad'"
            exit 198
        }
        foreach v of local endogenous {
            local found : list v in both
            if !`found' & "`endofunctions'" == "" {
                di as error "`v' is not in the model; declare its included functions in endofunctions()."
                exit 198
            }
        }
        local bad : list instruments & both
        if "`bad'" != "" {
            di as error "Excluded instruments also appear as structural regressors: `bad'"
            exit 198
        }
        local bad : list instruments & endogenous
        if "`bad'" != "" {
            di as error "An endogenous variable cannot instrument itself: `bad'"
            exit 198
        }
        local included : list both - endogenous
        local included : list included - endofunctions
        if "`rfvars'" != "" local included `rfvars'
        local bad : list included & endogenous
        local bad2 : list included & endofunctions
        if "`bad'`bad2'" != "" {
            di as error "The reduced-form instruments include declared endogenous terms: `bad' `bad2'"
            exit 198
        }
        local zvars `included' `instruments'
        local zvars : list uniq zvars
    }
    marksample touse
    local zbase ""
    if "`zvars'"!="" {
        quietly fvrevar `zvars', list
        local zbase "`r(varlist)'"
    }
    markout `touse' `id' `time' `uhet' `heterogeneity' `endogenous' `zbase' `clustvar'
    quietly count if `touse'
    if r(N) == 0 error 2000
    _tvtie_load
    tempname b V Voim runs diagnostics fs omega delta
    mata: _tvtie_fit("`b'","`V'","`Voim'","`runs'","`diagnostics'","`fs'","`omega'","`delta'")
    local N = el(`diagnostics',1,1)
    local Ng = el(`diagnostics',1,2)
    local k = el(`diagnostics',1,5)
    matrix colnames `runs' = start loglik score_scaled accepted nr_iterations return_code
    matrix colnames `diagnostics' = N N_g N_transformed k_het k_full k_profile ll score_scaled info_condition scale_survival accepted_starts dropped_panels N_clusters time_center time_scale sigma_r2 sigma_u2 mu sigma_v2
    ereturn post `b' `V', esample(`touse') obs(`N') depname(`depvar')
    ereturn scalar N_g = `Ng'
    ereturn scalar N_transformed = el(`diagnostics',1,3)
    ereturn scalar k_het = el(`diagnostics',1,4)
    ereturn scalar rank = `k'
    ereturn scalar k = `k'
    ereturn scalar k_profile = el(`diagnostics',1,6)
    ereturn scalar ll = el(`diagnostics',1,7)
    ereturn scalar score_scaled = el(`diagnostics',1,8)
    ereturn scalar information_condition = el(`diagnostics',1,9)
    ereturn scalar scale_survival = el(`diagnostics',1,10)
    ereturn scalar accepted_starts = el(`diagnostics',1,11)
    ereturn scalar dropped_panels = el(`diagnostics',1,12)
    if "`vcetype'" != "oim" ereturn scalar N_clust = el(`diagnostics',1,13)
    ereturn scalar time_center = el(`diagnostics',1,14)
    ereturn scalar time_scale = el(`diagnostics',1,15)
    ereturn scalar sigma_r2 = el(`diagnostics',1,16)
    ereturn scalar sigma_u2 = el(`diagnostics',1,17)
    ereturn scalar mu = el(`diagnostics',1,18)
    ereturn scalar sigma_v2 = el(`diagnostics',1,19)
    ereturn scalar converged = 1
    ereturn scalar trend = `trend'
    ereturn scalar het_constant = `_tvtie_hetcons'
    ereturn scalar absorbs_constant = `_tvtie_absorbscons'
    ereturn scalar frontier_constant = `_tvtie_xcons'
    ereturn scalar sign = cond("`cost'"!="",-1,1)
    ereturn scalar starts_requested = `starts'
    ereturn scalar seed = `seed'
    ereturn scalar tolerance = `tolerance'
    ereturn matrix V_oim = `Voim'
    ereturn matrix starts = `runs'
    ereturn matrix diagnostics = `diagnostics'
    if "`endogenous'" != "" {
        matrix rownames `fs' = `endogenous'
        matrix colnames `fs' = F p partial_R2 df1 df2
        matrix rownames `delta' = `_tvtie_znames'
        matrix colnames `delta' = `endogenous'
        matrix rownames `omega' = `endogenous'
        matrix colnames `omega' = `endogenous'
        ereturn matrix firststage = `fs'
        ereturn matrix delta = `delta'
        ereturn matrix Omega = `omega'
    }
    ereturn local depvar "`depvar'"
    ereturn local indepvars "`indepvars'"
    ereturn local uhet "`uhet'"
    ereturn local heterogeneity "`heterogeneity'"
    ereturn local ivar "`id'"
    ereturn local tvar "`time'"
    ereturn local endogenous "`endogenous'"
    ereturn local instruments "`instruments'"
    ereturn local endofunctions "`endofunctions'"
    ereturn local endof_declared "`declared_functions'"
    ereturn local endof_automatic "`automatic_functions'"
    ereturn local rfvars "`rfvars'"
    ereturn local zvars "`zvars_used'"
    ereturn local zvars_dropped "`zvars_dropped'"
    ereturn local data_signature "`_tvtie_signature'"
    ereturn local nohet "`nohet'"
    ereturn local nohetconstant "`nohetconstant'"
    ereturn local noconstant "`noconstant'"
    ereturn local cost "`cost'"
    ereturn local distribution "`distribution'"
    ereturn local vce "`vcetype'"
    if "`vcetype'" == "oim" ereturn local vcetype "OIM"
    else ereturn local vcetype "Robust"
    ereturn local clustvar "`clustvar'"
    ereturn local likelihood_unit "panel"
    ereturn local predict "tvtie_p"
    ereturn local estat_cmd "tvtie_estat"
    ereturn local marginsnotok "_ALL"
    ereturn local properties "b V"
    ereturn local title "Time-varying true individual-effects stochastic frontier"
    ereturn local model "TVTIE"
    if "`endogenous'" != "" ereturn local model "TVTIEE"
    ereturn local cmdline `"`cmdline'"'
    ereturn local package_version "1.2.0"
    ereturn local cmd "tvtie"
    if "`endogenous'" != "" {
        local restrictions ""
        foreach x of local endogenous {
            local restrictions `"`restrictions' ([eta]`x'=0)"'
        }
        quietly test `restrictions'
        ereturn scalar chi2_endogeneity = r(chi2)
        ereturn scalar df_endogeneity = r(df)
        ereturn scalar p_endogeneity = r(p)
    }
    if "`zvars_dropped'" != "" di as txt "Instruments absorbed by heterogeneity: `zvars_dropped'"
    if e(dropped_panels)>0 di as txt "Panels excluded by dropshort: " as res e(dropped_panels)
    _tvtie_display, level(`level')
end

program define _tvtie_display
    version 16.0
    syntax [, Level(cilevel)]
    di _n as txt "`e(title)' (`e(model)')"
    di as txt "Observations = " as res %10.0fc e(N) as txt "    Panels = " as res %8.0fc e(N_g)
    di as txt "Transformed dimension = " as res %10.0fc e(N_transformed) as txt "    Heterogeneity rank per panel = " as res e(k_het)
    di as txt "Log likelihood = " as res %15.7f e(ll) as txt "    Accepted starts = " as res e(accepted_starts) "/" e(starts_requested)
    ereturn display, level(`level')
    di as txt "Automatic heterogeneity intercept = " as res e(het_constant) as txt "    Common frontier intercept = " as res e(frontier_constant)
    di as txt "usigma parameterizes log(sigma_u^2 h_it^2); lnsig2r is the conditional noise log variance."
    di as txt "predict ..., efficiency gives exp(-E[u_it | transformed panel data])."
    if "`e(endogenous)'" != "" {
        di as txt "Endogenous variables: " as res "`e(endogenous)'"
        di as txt "Excluded instruments: " as res "`e(instruments)'"
        di as txt "Endogeneity test: chi2(" as res e(df_endogeneity) as txt ") = " as res %10.4f e(chi2_endogeneity) as txt "   Prob > chi2 = " as res %7.5f e(p_endogeneity)
        di as txt "H0: all eta coefficients are zero. See estat firststage for instrument diagnostics."
    }
    if e(scale_survival)<1e-5 di as txt "Warning: little of the fitted inefficiency scaling survives the projection; inspect estat diagnostics."
end
