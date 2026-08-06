*! causalimpact 1.0.0  05aug2026
*! Bayesian structural time-series causal impact analysis
*! Author: Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! GitHub: https://github.com/merwanroudane
*!
*! Implements Brodersen, Gallusser, Koehler, Remy and Scott (2015),
*! "Inferring causal impact using Bayesian structural time-series models",
*! Annals of Applied Statistics 9(1), 247-274.  DOI: 10.1214/14-AOAS788
*! Compatible with the R package CausalImpact 1.4.1 (google/CausalImpact),
*! whose source is bundled under reference_R/ for step-by-step comparison.
*!
*! ---------------------------------------------------------------------------
*! STEP -> EQUATION MAP        (full derivation: help causalimpact_methods)
*! ---------------------------------------------------------------------------
*!  S1  input / period checks ............ Sec. 1; R FormatInputForCausalImpact
*!  S2  pre-period standardisation ....... R impact_misc.R Standardize()
*!  S3  post-period response set missing . Sec. 2.3; R impact_analysis.R:411
*!  S4  state-space assembly ............. eq. (2.1)-(2.2)
*!  S5  local level block ................ eq. (2.3) with delta_t == 0
*!  S6  seasonal block ................... eq. (2.5)
*!  S7  static regression block .......... Sec. 2.1 "static coefficients"
*!  S8  dynamic regression block ......... eq. (2.6)
*!  S9  variance priors .................. eq. (2.7)
*! S10  spike-and-slab prior ............. eq. (2.8)-(2.9)
*! S11  slab / Zellner g-prior ........... eq. (2.10)-(2.12)
*! S12  Gibbs state draw (Durbin-Koopman)  Sec. 2.3 "Posterior simulation"
*! S13  Gibbs gamma / beta / sigma draw .. eq. (2.13)
*! S14  posterior predictive counterfactual eq. (2.14)
*! S15  pointwise causal effect .......... eq. (2.15)
*! S16  cumulative causal effect ......... eq. (2.16)
*! S17  running-average causal effect .... eq. (2.17)
*! S18  summary table / tail-area p ...... R CompileSummaryTable()
*! S19  verbal report .................... R InterpretSummaryTable()
*! S20  three-panel plot ................. Fig. 1, Fig. 5-7; R impact_plot.R
*! ---------------------------------------------------------------------------

program define causalimpact, eclass sortpreserve
    version 14.0

    * Replay.  The options that control DISPLAY must be honoured here too,
    * otherwise `causalimpact, report' silently redisplays the table only.
    if replay() {
        if ("`e(cmd)'" != "causalimpact") error 301
        syntax [, REPort NOTABle DIgits(integer 2) ]
        if ("`notable'" == "") _ci_display
        if ("`report'"  != "") _ci_report, digits(`digits')
        exit
    }

    syntax varlist(numeric ts min=1) [if] [in] ,        ///
        PREperiod(numlist min=2 max=2)                  ///
        POSTperiod(numlist min=2 max=2)                 ///
        [                                               ///
          NITer(integer 1000)                           ///
          BURNin(real -1)                               ///
          SEED(string)                                  ///
          ALpha(real 0.05)                              ///
          Level(cilevel)                                ///
          PRIORLevelsd(real 0.01)                       ///
          NSEasons(integer 1)                           ///
          SEASONDuration(integer 1)                     ///
          DYNamicregression                             ///
          NOSTANDardize                                 ///
          MAXFlips(integer -1)                          ///
          MODELsize(real 3)                             ///
          R2(real 0.8)                                  ///
          PRIORDf(real 50)                              ///
          GINFo(real 0.01)                              ///
          DSHRinkage(real 0.5)                          ///
          SIGMAUpper(real -1)                           ///
          NOCONstant                                    ///
          GRaph                                         ///
          METRics(string)                               ///
          NAME(string)                                  ///
          SAVing(string)                                ///
          LEGend                                        ///
          COEFplot                                      ///
          REPort                                        ///
          DIgits(integer 2)                             ///
          GENerate(string)                              ///
          REPLACE                                       ///
          NOTABle                                       ///
          NODOTs                                        ///
        ]

    * ---------------------------------------------------------------- S1 ---
    qui tsset
    local tvar   "`r(timevar)'"
    local pvar   "`r(panelvar)'"
    local tdelta = r(tdelta)
    if ("`tvar'" == "") {
        di as err "data must be {help tsset:tsset} before using causalimpact"
        exit 459
    }
    if ("`pvar'" != "") {
        di as err "causalimpact analyses a single time series, but the data are"
        di as err "{help xtset:xtset} on panel variable {bf:`pvar'}."
        di as err "Select one unit, e.g.  causalimpact y x1 if `pvar'==1, ..."
        exit 459
    }

    if (`level' != c(level)) local alpha = 1 - `level'/100
    else                     local level = 100*(1 - `alpha')
    if (`alpha' <= 0 | `alpha' >= 1) {
        di as err "alpha() must lie strictly between 0 and 1"
        exit 198
    }

    tsrevar `varlist'
    local rvlist "`r(varlist)'"
    gettoken depvar  covars  : rvlist
    gettoken dispdep dispcov : varlist

    local J : word count `covars'
    local hasx = (`J' > 0)

    marksample touse, novarlist
    if (`hasx') markout `touse' `covars'
    qui count if `touse'
    if (r(N) < 4) {
        di as err "too few usable observations (need at least 4)"
        exit 2001
    }

    * ---------------------------------------------------------------- S1 ---
    if (`niter' < 10) {
        di as err "must draw, at the very least, 10 MCMC samples; recommending 1000"
        exit 198
    }
    if (`niter' < 1000) {
        di as txt "{p 0 2}note: results potentially inaccurate; consider using" ///
                  " more MCMC samples, e.g. niter(1000).{p_end}"
    }
    if (`burnin' < 0) local burnin = round(0.1*`niter')
    local burnin = round(`burnin')
    if (`burnin' < 1) local burnin = 1
    if (`burnin' >= `niter') {
        di as err "burnin() must be smaller than niter()"
        exit 198
    }
    if (`priorlevelsd' <= 0) {
        di as err "priorlevelsd() must be strictly positive"
        exit 198
    }
    if (`nseasons' < 1) {
        di as err "nseasons() cannot be 0; use 1 in order not to have a seasonal component"
        exit 198
    }
    if (`seasonduration' < 1) {
        di as err "seasonduration() must be at least 1"
        exit 198
    }
    if (`maxflips' <= 0 & `maxflips' != -1) {
        di as err "maxflips() must be positive, or -1 for no limit"
        exit 198
    }
    if (`r2' <= 0 | `r2' >= 1) {
        di as err "r2() must lie strictly between 0 and 1"
        exit 198
    }
    if (`priordf' <= 0) {
        di as err "priordf() must be strictly positive"
        exit 198
    }
    if (`modelsize' <= 0) {
        di as err "modelsize() must be strictly positive"
        exit 198
    }
    if (`dshrinkage' < 0 | `dshrinkage' > 1) {
        di as err "dshrinkage() must lie in [0,1]"
        exit 198
    }
    if (`ginfo' <= 0) {
        di as err "ginfo() must be strictly positive"
        exit 198
    }

    local dynreg = ("`dynamicregression'" != "")
    local stdz   = ("`nostandardize'" == "")
    local addcon = ("`noconstant'" == "")
    local dots   = ("`nodots'" == "")
    if (`dynreg' & !`hasx') {
        di as err "dynamicregression requires at least one covariate"
        exit 198
    }

    if ("`seed'" != "") {
        capture set seed `seed'
        if (_rc) {
            di as err "invalid seed()"
            exit 198
        }
    }

    gettoken pre1  pre2  : preperiod
    gettoken post1 post2 : postperiod
    if (`pre1' > `pre2') {
        di as err "preperiod(): the first element must not exceed the second"
        exit 198
    }
    if (`post1' > `post2') {
        di as err "postperiod(): the first element must not exceed the second"
        exit 198
    }
    if (`post1' <= `pre2') {
        di as err "the post-period must start after the pre-period ends"
        exit 198
    }

    sort `tvar'

    tempvar gapchk
    qui gen double `gapchk' = `tvar' - `tvar'[_n-1] if `touse' & `touse'[_n-1]
    qui summarize `gapchk' if `touse', meanonly
    local maxgap = r(max)
    if (`maxgap' < . & `tdelta' < . & `maxgap' > `tdelta') {
        di as txt "{p 0 2}note: the selected sample has gaps in {bf:`tvar'}." ///
                  " Like the R package, causalimpact models the data in row"  ///
                  " order and ignores the gaps; consider {help tsfill} if a"  ///
                  " seasonal component is used.{p_end}"
    }

    * ------------------------------------------------------- S2 .. S17 -----
    tempvar s_resp s_cumresp s_pred s_predlo s_predup s_cpred s_cpredlo
    tempvar s_cpredup s_eff s_efflo s_effup s_ceff s_cefflo s_ceffup s_avgeff
    foreach v in s_resp s_cumresp s_pred s_predlo s_predup s_cpred s_cpredlo ///
                 s_cpredup s_eff s_efflo s_effup s_ceff s_cefflo s_ceffup    ///
                 s_avgeff {
        qui gen double ``v'' = .
    }

    tempname SUM INCL BB VV

    local e_ci_ok  = 1
    local e_ci_msg ""

    mata: _ci_main()

    if (`e_ci_ok' == 0) {
        di as err "`e_ci_msg'"
        di as err "inference aborted"
        exit 498
    }

    * ---------------------------------------------------------------- S20 ---
    if ("`generate'" != "") {
        local gvars pred lower upper cum_pred cum_lower cum_upper           ///
                    effect effect_lower effect_upper cum_effect             ///
                    cum_effect_lower cum_effect_upper response cum_response ///
                    avg_effect
        local gsrc  `s_pred' `s_predlo' `s_predup' `s_cpred' `s_cpredlo'    ///
                    `s_cpredup' `s_eff' `s_efflo' `s_effup' `s_ceff'        ///
                    `s_cefflo' `s_ceffup' `s_resp' `s_cumresp' `s_avgeff'
        if ("`replace'" != "") {
            foreach g of local gvars {
                capture drop `generate'_`g'
            }
        }
        foreach g of local gvars {
            capture confirm new variable `generate'_`g'
            if (_rc) {
                di as err "variable `generate'_`g' already exists; use the replace option"
                exit 110
            }
        }
        local k = 1
        foreach g of local gvars {
            local src : word `k' of `gsrc'
            qui gen double `generate'_`g' = `src'
            local k = `k' + 1
        }
        label variable `generate'_pred       "Counterfactual (posterior mean)"
        label variable `generate'_lower      "Counterfactual lower `level'% bound"
        label variable `generate'_upper      "Counterfactual upper `level'% bound"
        label variable `generate'_effect     "Pointwise causal effect"
        label variable `generate'_cum_effect "Cumulative causal effect"
        label variable `generate'_avg_effect "Running-average causal effect"
    }

    * Graphs are built BEFORE any matrix is moved into e()  (stata-package #6)
    if ("`graph'" != "" | "`saving'" != "" | "`metrics'" != "") {
        _ci_plot, tvar(`tvar') touse(`touse')                                   ///
            resp(`s_resp') pred(`s_pred') predlo(`s_predlo') predup(`s_predup') ///
            eff(`s_eff') efflo(`s_efflo') effup(`s_effup')                      ///
            ceff(`s_ceff') cefflo(`s_cefflo') ceffup(`s_ceffup')                ///
            pre2(`pre2') post2(`post2')                                         ///
            metrics(`metrics') name(`name') saving(`saving')                    ///
            level(`level') depvar(`dispdep') `legend'
    }
    if ("`coefplot'" != "" & `hasx') {
        _ci_coefplot, incl(`INCL') name(`name')
    }

    * ------------------------------------------------------------ ereturn ---
    if (`hasx') {
        ereturn post `BB' `VV', esample(`touse')
    }
    else {
        ereturn post, esample(`touse')
    }
    ereturn local depvar "`dispdep'"

    ereturn matrix summary = `SUM'
    if (`hasx') ereturn matrix inclusion = `INCL'

    ereturn scalar N                = `e_ci_N'
    ereturn scalar N_pre            = `e_ci_npre'
    ereturn scalar N_post           = `e_ci_npost'
    ereturn scalar N_model          = `e_ci_nmodel'
    ereturn scalar niter            = `niter'
    ereturn scalar burnin           = `burnin'
    ereturn scalar ndraws           = `niter' - `burnin'
    ereturn scalar alpha            = `alpha'
    ereturn scalar level            = `level'
    ereturn scalar p                = `e_ci_p'
    ereturn scalar prob_effect      = 1 - `e_ci_p'
    ereturn scalar actual_avg       = `e_ci_act1'
    ereturn scalar actual_cum       = `e_ci_act2'
    ereturn scalar pred_avg         = `e_ci_pred1'
    ereturn scalar pred_cum         = `e_ci_pred2'
    ereturn scalar abseffect        = `e_ci_abs1'
    ereturn scalar abseffect_sd     = `e_ci_abssd1'
    ereturn scalar abseffect_cum    = `e_ci_abs2'
    ereturn scalar abseffect_cum_sd = `e_ci_abssd2'
    ereturn scalar releffect        = `e_ci_rel1'
    ereturn scalar releffect_sd     = `e_ci_relsd1'
    ereturn scalar sigma_obs        = `e_ci_sobs'
    ereturn scalar sigma_level      = `e_ci_slev'
    if (`nseasons' > 1) ereturn scalar sigma_seas = `e_ci_sseas'
    ereturn scalar priorlevelsd     = `priorlevelsd'
    ereturn scalar nseasons         = `nseasons'
    ereturn scalar seasonduration   = `seasonduration'
    ereturn scalar modelsize        = `modelsize'
    ereturn scalar r2               = `r2'
    ereturn scalar priordf          = `priordf'
    ereturn scalar ginfo            = `ginfo'
    ereturn scalar dshrinkage       = `dshrinkage'
    ereturn scalar maxflips         = `maxflips'
    ereturn scalar k_covariates     = `J'

    local regtxt "none"
    if (`hasx' & `dynreg')  local regtxt "dynamic (time-varying coefficients)"
    if (`hasx' & !`dynreg') local regtxt "static spike-and-slab"
    local modtxt "local level"
    if (`nseasons' > 1) local modtxt "`modtxt' + seasonal(`nseasons')"
    if (`hasx')         local modtxt "`modtxt' + regression"
    local stdtxt "no"
    if (`stdz') local stdtxt "yes"

    ereturn local pre_period  "`pre1' `pre2'"
    ereturn local post_period "`post1' `post2'"
    ereturn local timevar     "`tvar'"
    ereturn local covariates  "`dispcov'"
    ereturn local standardize "`stdtxt'"
    ereturn local regression  "`regtxt'"
    ereturn local model       "`modtxt'"
    ereturn local predict     "causalimpact_p"
    ereturn local title       "Bayesian structural time-series causal impact"
    ereturn local cmdline     "causalimpact `0'"
    ereturn local cmd         "causalimpact"

    if ("`notable'" == "") _ci_display
    if ("`report'"  != "") _ci_report, digits(`digits')
end


* =========================================================================== *
*  S18  Summary table                                                          *
* =========================================================================== *
program define _ci_display
    version 14.0

    tempname S
    matrix `S' = e(summary)

    local lev = e(level)
    local ci  = "`lev'% CI"
    local p   = e(p)

    local act1 = `S'[1,1]
    local act2 = `S'[2,1]
    local pr1  = `S'[1,2]
    local pr2  = `S'[2,2]
    local pl1  = `S'[1,3]
    local pl2  = `S'[2,3]
    local pu1  = `S'[1,4]
    local pu2  = `S'[2,4]
    local ps1  = `S'[1,5]
    local ps2  = `S'[2,5]
    local ae1  = `S'[1,6]
    local ae2  = `S'[2,6]
    local al1  = `S'[1,7]
    local al2  = `S'[2,7]
    local au1  = `S'[1,8]
    local au2  = `S'[2,8]
    local as1  = `S'[1,9]
    local as2  = `S'[2,9]
    local re1  = 100*`S'[1,10]
    local re2  = 100*`S'[2,10]
    local rl1  = 100*`S'[1,11]
    local rl2  = 100*`S'[2,11]
    local ru1  = 100*`S'[1,12]
    local ru2  = 100*`S'[2,12]
    local rs1  = 100*`S'[1,13]
    local rs2  = 100*`S'[2,13]

    local star " "
    if (`rl1' > 0 | `ru1' < 0) local star "*"
    if (`p' < 0.05)            local star "**"
    if (`p' < 0.01)            local star "***"

    local cov = trim("`e(covariates)'")
    if ("`cov'" == "") local cov "(none)"
    if (length("`cov'") > 29) local cov = substr("`cov'", 1, 26) + "..."
    local mdl = trim("`e(model)'")
    if (length("`mdl'") > 29) local mdl = substr("`mdl'", 1, 26) + "..."
    local reg = trim("`e(regression)'")
    if (length("`reg'") > 29) local reg = substr("`reg'", 1, 26) + "..."
    local dep = abbrev("`e(depvar)'", 29)

    di ""
    di as txt "{hline 79}"
    di as txt "Bayesian causal impact analysis  (Brodersen et al. 2015, AOAS 9:247-274)"
    di as txt "{hline 79}"
    di as txt "Response         " as res "`dep'"                             ///
       as txt _col(48) "Obs (total)  =" as res %10.0f e(N)
    di as txt "Covariates       " as res "`cov'"                             ///
       as txt _col(48) "Obs (pre)    =" as res %10.0f e(N_pre)
    di as txt "State model      " as res "`mdl'"                             ///
       as txt _col(48) "Obs (post)   =" as res %10.0f e(N_post)
    di as txt "Regression       " as res "`reg'"                             ///
       as txt _col(48) "Covariates   =" as res %10.0f e(k_covariates)
    di as txt "Standardised     " as res "`e(standardize)'"                  ///
       as txt _col(48) "MCMC draws   =" as res %10.0f e(niter)
    di as txt "Pre-period       " as res "`e(pre_period)'"                   ///
       as txt _col(48) "Burn-in      =" as res %10.0f e(burnin)
    di as txt "Post-period      " as res "`e(post_period)'"                  ///
       as txt _col(48) "Retained     =" as res %10.0f e(ndraws)
    di as txt "{hline 79}"
    di as txt _col(32) "Average" _col(58) "Cumulative"
    di as txt "{hline 79}"
    di as txt "Actual"                as res _col(28) %12.4g `act1' _col(53) %14.4g `act2'
    di as txt "Prediction"            as res _col(28) %12.4g `pr1'  _col(53) %14.4g `pr2'
    di as txt "  posterior s.d."      as res _col(28) %12.4g `ps1'  _col(53) %14.4g `ps2'
    di as txt "  `ci'"                as res _col(24) "[" %9.4g `pl1' "," %9.4g `pu1' "]" ///
                                             _col(50) "[" %10.4g `pl2' "," %10.4g `pu2' "]"
    di as txt "{hline 79}"
    di as txt "Absolute effect"       as res _col(28) %12.4g `ae1'  _col(53) %14.4g `ae2'
    di as txt "  posterior s.d."      as res _col(28) %12.4g `as1'  _col(53) %14.4g `as2'
    di as txt "  `ci'"                as res _col(24) "[" %9.4g `al1' "," %9.4g `au1' "]" ///
                                             _col(50) "[" %10.4g `al2' "," %10.4g `au2' "]"
    di as txt "{hline 79}"
    di as txt "Relative effect (%)"   as res _col(28) %12.3f `re1'  _col(53) %14.3f `re2'
    di as txt "  posterior s.d."      as res _col(28) %12.3f `rs1'  _col(53) %14.3f `rs2'
    di as txt "  `ci'"                as res _col(24) "[" %9.3f `rl1' "," %9.3f `ru1' "]" ///
                                             _col(50) "[" %10.3f `rl2' "," %10.3f `ru2' "]"
    di as txt "{hline 79}"
    di as txt "Posterior tail-area probability  p" as res _col(40) %12.5f `p' "  " as txt "`star'"
    di as txt "Posterior probability of an effect" as res _col(40) %11.4f 100*(1-`p') "%"
    di as txt "{hline 79}"
    di as txt "*** p<.01, ** p<.05, * `lev'% credible interval of the effect excludes 0"
    di as txt "{p 0 2}Intervals are central (1-alpha) posterior credible intervals of" ///
              " the counterfactual; p is the one-sided Bayesian tail-area probability" ///
              " of the cumulative effect (eq. 2.16).{p_end}"

    if (e(k_covariates) > 0) _ci_incltable

    di as txt "{p 0 2}Type {stata causalimpact, report:causalimpact, report}" ///
              " for a verbal interpretation, or" ///
              " {stata help causalimpact_methods:help causalimpact methods}" ///
              " for the model.{p_end}"
    di ""
end


* =========================================================================== *
*  S10-S11  Spike-and-slab inclusion table                                     *
* =========================================================================== *
program define _ci_incltable
    version 14.0
    tempname I
    capture matrix `I' = e(inclusion)
    if (_rc) exit
    local Jd = rowsof(`I')
    local rn : rownames `I'

    di ""
    di as txt "Regression component: posterior summary of the synthetic control"
    di as txt "{hline 79}"
    di as txt "Covariate" _col(24) "P(incl)" _col(38) "Post. mean" ///
              _col(54) "Post. s.d." _col(68) "P(b>0)"
    di as txt "{hline 79}"
    forvalues j = 1/`Jd' {
        local nm : word `j' of `rn'
        di as txt %-22s abbrev("`nm'",22) as res             ///
           _col(23) %11.3f `I'[`j',1] _col(38) %12.4g `I'[`j',2] ///
           _col(54) %11.4g `I'[`j',3] _col(66) %11.3f `I'[`j',4]
    }
    di as txt "{hline 79}"
    di as txt "{p 0 2}P(incl) is the posterior inclusion probability of the" ///
              " spike-and-slab prior (eq. 2.8-2.9). Posterior mean and s.d." ///
              " are model-averaged: draws that exclude a covariate contribute" ///
              " a coefficient of exactly zero. P(b>0) is conditional on" ///
              " inclusion. As in the R package, coefficients are reported in" ///
              " the metric the model is fitted in (standardised, unless" ///
              " nostandardize was specified).{p_end}"
end


* =========================================================================== *
*  S19  Verbal report -- faithful port of R InterpretSummaryTable()            *
* =========================================================================== *
program define _ci_report
    version 14.0
    syntax [, DIgits(integer 2) ]

    if ("`e(cmd)'" != "causalimpact") error 301

    tempname S
    matrix `S' = e(summary)
    local alpha = e(alpha)
    local ci    = string(round(100*(1-`alpha'))) + "%"

    mata: _ci_report_strings(`digits')

    local sig = (!(`S'[1,11] < 0 & `S'[1,12] > 0))
    local pos = (`S'[1,10] > 0)
    local p   = e(p)
    * R prints round(p, 3) with a leading zero and trailing zeros dropped
    * ("0.001", "0.185"); Stata's string() drops the leading zero. Restore it
    * so the report is textually identical to summary(impact, "report") in R.
    local pr  = string(round(`p',0.001))
    if (substr("`pr'",1,1) == ".")  local pr = "0`pr'"
    if (substr("`pr'",1,2) == "-.") local pr = "-0" + substr("`pr'",2,.)

    local by1 "In"
    local by2 "Had"
    if (`sig') {
        local by1 "By contrast, in"
        local by2 "By contrast, had"
    }
    local dir "a decrease of"
    if (`pos') local dir "an increase of"

    di ""
    di as txt "{hline 79}"
    di as txt "Analysis report {causalimpact}"
    di as txt "{hline 79}"
    di ""

    _ci_wrap `"During the post-intervention period, the response variable had an average value of approx. `r_act1'. `by1' the absence of an intervention, we would have expected an average response of `r_pred1'. The `ci' interval of this counterfactual prediction is [`r_predlo1', `r_predup1']. Subtracting this prediction from the observed response yields an estimate of the causal effect the intervention had on the response variable. This effect is `r_abs1' with a `ci' interval of [`r_abslo1', `r_absup1']. For a discussion of the significance of this effect, see below."'
    di ""
    _ci_wrap `"Summing up the individual data points during the post-intervention period (which can only sometimes be meaningfully interpreted), the response variable had an overall value of `r_act2'. `by2' the intervention not taken place, we would have expected a sum of `r_pred2'. The `ci' interval of this prediction is [`r_predlo2', `r_predup2']."'
    di ""
    _ci_wrap `"The above results are given in terms of absolute numbers. In relative terms, the response variable showed `dir' `r_rel1'. The `ci' interval of this percentage is [`r_rello1', `r_relup1']."'

    local gap = abs(`S'[1,10] - `S'[1,6]/`S'[1,2])
    if (`gap' >= 0.05) {
        di ""
        _ci_wrap `"(Note that the expected relative effect isn't generally the same as the expected absolute effect divided by the expected prediction since distributions are often not symmetric.)"'
    }

    di ""
    if (`sig' & `pos') {
        _ci_wrap `"This means that the positive effect observed during the intervention period is statistically significant and unlikely to be due to random fluctuations. It should be noted, however, that the question of whether this increase also bears substantive significance can only be answered by comparing the absolute effect (`r_abs1') to the original goal of the underlying intervention."'
    }
    else if (`sig' & !`pos') {
        _ci_wrap `"This means that the negative effect observed during the intervention period is statistically significant. If the experimenter had expected a positive effect, it is recommended to double-check whether anomalies in the control variables may have caused an overly optimistic expectation of what should have happened in the response variable in the absence of the intervention."'
    }
    else if (!`sig' & `pos') {
        _ci_wrap `"This means that, although the intervention appears to have caused a positive effect, this effect is not statistically significant when considering the entire post-intervention period as a whole. Individual days or shorter stretches within the intervention period may of course still have had a significant effect, as indicated whenever the lower limit of the impact time series (lower plot) was above zero."'
    }
    else {
        _ci_wrap `"This means that, although it may look as though the intervention has exerted a negative effect on the response variable when considering the intervention period as a whole, this effect is not statistically significant, and so cannot be meaningfully interpreted."'
    }

    if (!`sig') {
        di ""
        _ci_wrap `"The apparent effect could be the result of random fluctuations that are unrelated to the intervention. This is often the case when the intervention period is very long and includes much of the time when the effect has already worn off. It can also be the case when the intervention period is too short to distinguish the signal from the noise. Finally, failing to find a significant effect can happen when there are not enough control variables or when these variables do not correlate well with the response variable during the learning period."'
    }

    di ""
    if (`p' < `alpha') {
        _ci_wrap `"The probability of obtaining this effect by chance is very small (Bayesian one-sided tail-area probability p = `pr'). This means the effect is statistically significant. It can be considered causal if the model assumptions are satisfied."'
    }
    else {
        _ci_wrap `"The probability of obtaining this effect by chance is p = `pr'. This means the effect may be spurious and would generally not be considered statistically significant."'
    }

    di ""
    _ci_wrap `"For more details, including the model assumptions behind the method, see help causalimpact_methods and Brodersen et al. (2015), Annals of Applied Statistics 9(1), 247-274."'
    di as txt "{hline 79}"
    di ""
end


program define _ci_wrap
    version 14.0
    args txt
    local w 78
    local s `"`txt'"'
    while (`"`s'"' != "") {
        local L = length(`"`s'"')
        if (`L' <= `w') {
            di as txt `"`s'"'
            local s ""
        }
        else {
            local cut = `w' + 1
            while (`cut' > 1 & substr(`"`s'"',`cut',1) != " ") {
                local cut = `cut' - 1
            }
            if (`cut' <= 1) local cut = `w' + 1
            di as txt `"`=substr(`"`s'"',1,`cut'-1)'"'
            local s = trim(substr(`"`s'"',`cut'+1,.))
        }
    }
end


* =========================================================================== *
*  S20  Three-panel plot -- Fig. 1 and Fig. 5-7 of the paper                    *
* =========================================================================== *
program define _ci_plot
    version 14.0
    syntax , tvar(varname) touse(varname)                                    ///
             resp(varname) pred(varname) predlo(varname) predup(varname)     ///
             eff(varname) efflo(varname) effup(varname)                      ///
             ceff(varname) cefflo(varname) ceffup(varname)                   ///
             pre2(string) post2(string)                                      ///
             level(string) depvar(string)                                    ///
             [ metrics(string) name(string) saving(string) LEGend ]

    if ("`metrics'" == "") local metrics "original pointwise cumulative"
    local metrics = lower("`metrics'")

    local gname "causalimpact"
    if ("`name'" != "") local gname "`name'"

    * ---- R palette ------------------------------------------------------
    * ggplot2 "slategray2"  = RGB 185 211 238   (the credible band)
    * ggplot2 "darkblue"    = RGB   0   0 139   (the counterfactual)
    * theme_bw panel border = grey20 = RGB  51  51  51
    * theme_bw grid lines   = grey92 = RGB 235 235 235
    * NOTE: RGB triples MUST be quoted in Stata, otherwise "185" is parsed
    * as a named style and silently falls back to the default colour.
    local cBAND  `""185 211 238""'
    local cPRED  `""0 0 139""'
    local cBORD  `""51 51 51""'
    local cGRID  `""235 235 235""'
    local cMARK  `""128 128 128""'

    local band  fcolor(`cBAND') lcolor(`cBAND') lwidth(none)
    local predl lcolor(`cPRED') lpattern(shortdash) lwidth(medthin)
    local respl lcolor(black) lwidth(medthin)

    * theme_bw look: white panel with a thin dark border and pale gridlines
    local sch   graphregion(color(white) margin(zero) lcolor(white))         ///
                plotregion(color(white) lcolor(`cBORD') lwidth(thin)         ///
                           margin(l=1 r=1 b=1 t=1))
    local ylab  ylabel(, labsize(vsmall) angle(0) format(%9.0g)              ///
                       grid glcolor(`cGRID') glwidth(vthin) glpattern(solid) ///
                       tlcolor(`cBORD'))
    local xlabS xlabel(, labsize(vsmall) nolabels                            ///
                       grid glcolor(`cGRID') glwidth(vthin) glpattern(solid) ///
                       tlcolor(`cBORD'))
    local xlabB xlabel(, labsize(vsmall)                                     ///
                       grid glcolor(`cGRID') glwidth(vthin) glpattern(solid) ///
                       tlcolor(`cBORD'))
    local vln   xline(`pre2' `post2', lpattern(dash) lcolor(`cMARK')         ///
                      lwidth(vthin))
    local zln   yline(0, lcolor(`cMARK') lwidth(vthin) lpattern(solid))

    * facet-strip label, right-hand side, as in facet_grid(metric ~ .)
    local strip1 subtitle("original", pos(3) orientation(rvertical)          ///
                    size(vsmall) box bcolor(`cGRID') bmargin(small)          ///
                    lcolor(`cBORD') lwidth(vthin))
    local strip2 subtitle("pointwise", pos(3) orientation(rvertical)         ///
                    size(vsmall) box bcolor(`cGRID') bmargin(small)          ///
                    lcolor(`cBORD') lwidth(vthin))
    local strip3 subtitle("cumulative", pos(3) orientation(rvertical)        ///
                    size(vsmall) box bcolor(`cGRID') bmargin(small)          ///
                    lcolor(`cBORD') lwidth(vthin))

    * R's plot carries no legend and no axis titles; both are opt-in here.
    local leg legend(off)
    if ("`legend'" != "") {
        local leg legend(order(3 "Observed" 2 "Counterfactual"               ///
                               1 "`level'% credible interval")               ///
                         rows(1) size(vsmall) region(lcolor(white))          ///
                         symxsize(6) pos(6))
    }

    local todraw ""
    local nsel = 0
    if (strpos("`metrics'","orig")) local nsel = `nsel' + 1
    if (strpos("`metrics'","point")) local nsel = `nsel' + 1
    if (strpos("`metrics'","cum")) local nsel = `nsel' + 1
    local kdone = 0

    if (strpos("`metrics'","orig")) {
        local kdone = `kdone' + 1
        local xl "`xlabS'"
        if (`kdone' == `nsel') local xl "`xlabB'"
        capture graph drop `gname'_original
        twoway (rarea `predup' `predlo' `tvar' if `touse', `band')       ///
               (line `pred' `tvar' if `touse', `predl')                  ///
               (line `resp' `tvar' if `touse', `respl'),                 ///
               `sch' `vln' `ylab' `xl' `strip1' `leg'                    ///
               ytitle("") xtitle("")                                     ///
               name(`gname'_original, replace) nodraw
        local todraw "`todraw' `gname'_original"
    }
    if (strpos("`metrics'","point")) {
        local kdone = `kdone' + 1
        local xl "`xlabS'"
        if (`kdone' == `nsel') local xl "`xlabB'"
        capture graph drop `gname'_pointwise
        twoway (rarea `effup' `efflo' `tvar' if `touse', `band')         ///
               (line `eff' `tvar' if `touse', `predl'),                  ///
               `sch' `vln' `zln' `ylab' `xl' `strip2'                    ///
               ytitle("") xtitle("") legend(off)                         ///
               name(`gname'_pointwise, replace) nodraw
        local todraw "`todraw' `gname'_pointwise"
    }
    if (strpos("`metrics'","cum")) {
        local kdone = `kdone' + 1
        capture graph drop `gname'_cumulative
        twoway (rarea `ceffup' `cefflo' `tvar' if `touse', `band')       ///
               (line `ceff' `tvar' if `touse', `predl'),                 ///
               `sch' `vln' `zln' `ylab' `xlabB' `strip3'                 ///
               ytitle("") xtitle("") legend(off)                         ///
               name(`gname'_cumulative, replace) nodraw
        local todraw "`todraw' `gname'_cumulative"
    }

    local nplot : word count `todraw'
    if (`nplot' == 0) exit

    if (`nplot' == 1) {
        local final : word 1 of `todraw'
        graph display `final'
    }
    else {
        capture graph drop `gname'
        graph combine `todraw', cols(1)                                  ///
            graphregion(color(white) margin(zero)) imargin(zero)         ///
            ysize(`=2.0*`nplot'') xsize(6.5)                             ///
            name(`gname', replace)
        local final "`gname'"
    }
    if (`"`saving'"' != "") {
        graph save `final' `saving', replace
    }
end


* =========================================================================== *
*  Inclusion plot (companion to R plot(bsts.model, "coefficients"))            *
* =========================================================================== *
program define _ci_coefplot
    version 14.0
    syntax , incl(name) [ name(string) ]

    * Reproduces BoomSpikeSlab::PlotMarginalInclusionProbabilities, which is
    * what plot(bsts.model, "coefficients") draws in R: covariates ordered by
    * posterior inclusion probability with the largest at the top, each bar
    * shaded by the conditional probability that the coefficient is positive
    * given that it is in the model.  R uses a white-to-black ramp; here the
    * same information is carried on a blue ramp running from a pale blue
    * (negative) to darkblue RGB 0 0 139 (positive) -- the top of the ramp is
    * exactly the colour of the counterfactual line in the impact figure, so
    * the two figures read as one family.  A single linear ramp is used rather
    * than one bent through slategray2, because the pale end and slategray2
    * are too close to tell apart at bar size.

    local gname "causalimpact_coef"
    if ("`name'" != "") local gname "`name'_coef"

    tempname I
    matrix `I' = `incl'
    local Jd = rowsof(`I')
    local rn : rownames `I'

    local cBORD `""51 51 51""'
    local cGRID `""235 235 235""'
    * ramp endpoints: pale blue -> darkblue (0 0 139), through slategray2
    local rLO = 222
    local gLO = 235
    local bLO = 250
    local rHI = 0
    local gHI = 0
    local bHI = 139

    local maxbar = 60
    local trunc  = 0
    if (`Jd' > `maxbar') {
        local trunc = 1
        di as txt "{p 0 2}note: only the `maxbar' covariates with the highest" ///
                  " posterior inclusion probability are plotted.{p_end}"
    }

    preserve
    clear
    qui set obs `Jd'
    qui svmat double `I', name(ci_)
    qui gen int ci_row = _n
    qui gen str32 ci_nm = ""
    forvalues j = 1/`Jd' {
        local nm : word `j' of `rn'
        qui replace ci_nm = "`nm'" in `j'
    }

    * largest inclusion probability at the TOP, as in R
    gsort ci_1 -ci_row
    qui gen int ci_ord = _n
    if (`trunc') {
        qui drop if ci_ord <= `Jd' - `maxbar'
        qui replace ci_ord = ci_ord - (`Jd' - `maxbar')
    }
    qui count
    local nb = r(N)

    local lb ""
    local cmd ""
    forvalues j = 1/`nb' {
        local nmj = ci_nm[`j']
        local lb  `"`lb' `j' "`=abbrev("`nmj'",18)'""'
        local pp  = ci_4[`j']
        if (`pp' >= .) local pp = 0.5
        if (`pp' < 0)  local pp = 0
        if (`pp' > 1)  local pp = 1
        local rr = round(`rLO' + `pp'*(`rHI' - `rLO'))
        local gg = round(`gLO' + `pp'*(`gHI' - `gLO'))
        local bb = round(`bLO' + `pp'*(`bHI' - `bLO'))
        local cbar `""`rr' `gg' `bb'""'
        local cmd `"`cmd' (bar ci_1 ci_ord if ci_ord==`j', horizontal"'
        local cmd `"`cmd' barwidth(0.68) fcolor(`cbar') lcolor(`cBORD')"'
        local cmd `"`cmd' lwidth(vthin))"'
    }

    capture graph drop `gname'
    twoway `cmd',                                                             ///
           graphregion(color(white) margin(zero))                             ///
           plotregion(color(white) lcolor(`cBORD') lwidth(thin))              ///
           title("Posterior inclusion probabilities", size(medsmall) pos(11)) ///
           subtitle("shading: P(coefficient > 0 | included)"                  ///
                    " -- pale negative, dark blue positive",                  ///
                    size(vsmall) pos(11) margin(b=2))                         ///
           xtitle("P(inclusion)", size(small))                                ///
           ytitle("")                                                         ///
           ylabel(`lb', angle(0) labsize(vsmall) nogrid                       ///
                  tlcolor(`cBORD'))                                           ///
           yscale(range(0.3 `=`nb'+0.7'))                                     ///
           xlabel(0(0.2)1, format(%3.1f) labsize(vsmall)                      ///
                  grid glcolor(`cGRID') glwidth(vthin) glpattern(solid))      ///
           xscale(range(0 1))                                                 ///
           legend(off)                                                        ///
           name(`gname', replace)
    restore
end


* =========================================================================== *
*                               MATA ENGINE                                    *
* =========================================================================== *
version 14.0
mata:

// Assembled state-space model, eq. (2.1)-(2.2)
struct cissm {
    real matrix    Tadv, Thold, P1
    real colvector a1, adv
    real scalar    d, S, dur, m, nx, dyn, dss
}

// -------------------------------------------------------------------------
// R-compatible quantile (stats::quantile type 7); xs sorted ascending.
// -------------------------------------------------------------------------
real scalar _ci_quantile(real colvector xs, real scalar p)
{
    real scalar n, h, lo
    n = rows(xs)
    if (n == 1) {
        return(xs[1])
    }
    h  = (n - 1)*p + 1
    lo = floor(h)
    if (lo < 1) {
        return(xs[1])
    }
    if (lo >= n) {
        return(xs[n])
    }
    return(xs[lo] + (h - lo)*(xs[lo+1] - xs[lo]))
}

real scalar _ci_qcol(real colvector x, real scalar p)
{
    real colvector xs
    xs = sort(x, 1)
    return(_ci_quantile(xs, p))
}

// log|A| via Cholesky; missing when A is not positive definite.
real scalar _ci_logdet(real matrix A)
{
    real matrix    L
    real colvector dg
    if (rows(A) == 0) {
        return(0)
    }
    L = cholesky(A)
    if (hasmissing(L)) {
        return(.)
    }
    dg = diagonal(L)
    if (min(dg) <= 0) {
        return(.)
    }
    return(2*sum(log(dg)))
}

// -------------------------------------------------------------------------
// S9  Draw sigma^2 from its inverse-Gamma full conditional, eq. (2.7),
//     truncated so that sigma <= uplim (Boom SdPrior upper.limit).
//       prior 1/sigma^2 ~ G(df/2, ss/2),  ss = df * guess^2
//       post  1/sigma^2 ~ G((df+n)/2, (ss+sumsq)/2)
// -------------------------------------------------------------------------
real scalar _ci_draw_sig2(real scalar df, real scalar ss, real scalar n,
                          real scalar sumsq, real scalar uplim)
{
    real scalar a, b, plow, u, prec, lo
    a = (df + n)/2
    b = 2/(ss + sumsq)
    if (a <= 0 | b <= 0) {
        return(.)
    }
    if (uplim >= . | uplim <= 0) {
        return(1/rgamma(1, 1, a, b))
    }
    lo   = 1/(uplim*uplim)
    plow = gammap(a, lo/b)
    if (plow > 0.9999999) {
        return(uplim*uplim)
    }
    u = plow + (1 - plow)*runiform(1, 1)
    if (u >= 1) {
        u = 1 - 1e-12
    }
    prec = b*invgammap(a, u)
    if (prec <= 0) {
        return(uplim*uplim)
    }
    return(1/prec)
}

// -------------------------------------------------------------------------
// S12  Kalman filter (univariate y, possibly missing).  Stores v, F, K,
//      which is all the fast state smoother needs.
// -------------------------------------------------------------------------
void _ci_filter(real colvector y, struct cissm scalar M, real matrix Zmat,
                real scalar s2obs, real colvector RQRd, real colvector a1use,
                real colvector v, real colvector F, real matrix K)
{
    real scalar    t, m, d, Ft
    real colvector a, Zt, PZ, Kt
    real matrix    P, Tt, L, RQ

    m  = M.m
    d  = M.d
    v  = J(m, 1, 0)
    F  = J(m, 1, .)
    K  = J(d, m, 0)
    a  = a1use
    P  = M.P1
    RQ = diag(RQRd)

    for (t = 1; t <= m; t++) {
        Tt = M.Thold
        if (M.adv[t] == 1) {
            Tt = M.Tadv
        }
        Zt = Zmat[., t]
        if (y[t] < .) {
            PZ = P*Zt
            Ft = Zt'PZ + s2obs
            if (Ft <= 0) {
                Ft = 1e-12
            }
            v[t]    = y[t] - Zt'a
            F[t]    = Ft
            Kt      = (Tt*PZ)/Ft
            K[., t] = Kt
            L       = Tt - Kt*Zt'
            a       = Tt*a + Kt*v[t]
            P       = Tt*P*L'
        }
        else {
            v[t] = 0
            F[t] = .
            a    = Tt*a
            P    = Tt*P*Tt'
        }
        P = P + RQ
        P = (P + P')/2
    }
}

// -------------------------------------------------------------------------
// S12  Fast state smoother of Durbin and Koopman (2002).
// -------------------------------------------------------------------------
real matrix _ci_smooth(struct cissm scalar M, real matrix Zmat,
                       real colvector v, real colvector F, real matrix K,
                       real colvector RQRd, real colvector a1use)
{
    real scalar    t, m, d
    real colvector r, Zt
    real matrix    ah, Tt, L, rstore

    m      = M.m
    d      = M.d
    ah     = J(d, m, 0)
    rstore = J(d, m + 1, 0)
    r      = J(d, 1, 0)

    for (t = m; t >= 1; t--) {
        Tt = M.Thold
        if (M.adv[t] == 1) {
            Tt = M.Tadv
        }
        Zt = Zmat[., t]
        if (F[t] < .) {
            L = Tt - K[., t]*Zt'
            r = Zt*(v[t]/F[t]) + L'r
        }
        else {
            r = Tt'r
        }
        rstore[., t] = r
    }

    ah[., 1] = a1use + M.P1*rstore[., 1]
    for (t = 1; t <= m - 1; t++) {
        Tt = M.Thold
        if (M.adv[t] == 1) {
            Tt = M.Tadv
        }
        ah[., t+1] = Tt*ah[., t] + RQRd:*rstore[., t+1]
    }
    return(ah)
}

// -------------------------------------------------------------------------
// S12  Durbin-Koopman (2002) simulation smoother.
//
// The textbook recipe alpha~ = ahat(y) - ahat(y+) + alpha+ needs TWO smoother
// passes.  Because the smoother is affine in (y, a1) with the same a1 in both,
//     ahat(y) - ahat(y+) = ahat(y - y+ ; a1 = 0),
// so a SINGLE pass on y* = y - y+ with a zero initial mean is algebraically
// identical at half the cost.  See help causalimpact_methods, Step 12.
// -------------------------------------------------------------------------
real matrix _ci_simsmooth(real colvector y, struct cissm scalar M,
                          real matrix Zmat, real scalar s2obs,
                          real colvector RQRd)
{
    real scalar    t, m, d
    real colvector ap, ystar, v, F, zero1, eta, sdq
    real matrix    aplus, K, ahat, Tt, Lch

    m     = M.m
    d     = M.d
    aplus = J(d, m, 0)
    ystar = J(m, 1, .)
    sdq   = sqrt(RQRd)

    Lch = cholesky(M.P1)
    if (hasmissing(Lch)) {
        Lch = diag(sqrt(diagonal(M.P1)))
    }
    ap = M.a1 + Lch*rnormal(d, 1, 0, 1)

    for (t = 1; t <= m; t++) {
        aplus[., t] = ap
        if (y[t] < .) {
            ystar[t] = y[t] - (Zmat[., t]'ap + rnormal(1, 1, 0, sqrt(s2obs)))
        }
        if (t < m) {
            Tt = M.Thold
            if (M.adv[t] == 1) {
                Tt = M.Tadv
            }
            eta = sdq:*rnormal(d, 1, 0, 1)
            ap  = Tt*ap + eta
        }
    }

    zero1 = J(d, 1, 0)
    _ci_filter(ystar, M, Zmat, s2obs, RQRd, zero1, v, F, K)
    ahat = _ci_smooth(M, Zmat, v, F, K, RQRd, zero1)

    return(ahat + aplus)
}

// -------------------------------------------------------------------------
// S13  Log marginal posterior of an inclusion vector, eq. (2.13):
//        V^-1 = X'X + Omega^-1
//        btil = V (X'ydot + Omega^-1 b)
//        N    = nu_eps + n
//        S    = s_eps + ydot'ydot + b'Omega^-1 b - btil' V^-1 btil
//      log p  = log p(gamma) + .5 log|Omega^-1| - .5 log|V^-1| - (N/2) log S
// -------------------------------------------------------------------------
real scalar _ci_logmarg(real colvector g, real matrix XtX, real colvector Xty,
                        real scalar yty, real matrix Om, real colvector bpr,
                        real scalar nu, real scalar seps, real scalar n,
                        real colvector logpi, real colvector log1mpi,
                        real scalar Sout)
{
    real colvector idx, xb, ob, btil
    real matrix    Omg, Vinv
    real scalar    k, ld1, ld2, Sg, Nn, lp

    idx = selectindex(g :> 0)
    k   = length(idx)
    Nn  = nu + n
    lp  = quadsum(g:*logpi) + quadsum((1 :- g):*log1mpi)

    if (k == 0) {
        Sg = seps + yty
        if (Sg <= 0) {
            return(.)
        }
        Sout = Sg
        return(lp - (Nn/2)*log(Sg))
    }
    if (k >= n) {
        return(.)
    }

    Omg  = Om[idx, idx]
    Vinv = XtX[idx, idx] + Omg
    ld1  = _ci_logdet(Omg)
    ld2  = _ci_logdet(Vinv)
    if (ld1 >= . | ld2 >= .) {
        return(.)
    }
    xb   = Xty[idx]
    ob   = Omg*bpr[idx]
    btil = cholsolve(Vinv, xb + ob)
    if (hasmissing(btil)) {
        btil = invsym(Vinv)*(xb + ob)
    }
    Sg = seps + yty + bpr[idx]'ob - btil'Vinv*btil
    if (Sg <= 0) {
        return(.)
    }
    Sout = Sg
    return(lp + 0.5*ld1 - 0.5*ld2 - (Nn/2)*log(Sg))
}

// -------------------------------------------------------------------------
// S13  One stochastic-search sweep over gamma, then conjugate draws of
//      sigma_eps^2 and beta.  g, beta and s2obs are updated in place.
// -------------------------------------------------------------------------
void _ci_ssvs(real colvector g, real colvector beta, real scalar s2obs,
              real matrix XtX, real colvector Xty, real scalar yty,
              real matrix Om, real colvector bpr, real scalar nu,
              real scalar seps, real scalar n, real colvector logpi,
              real colvector log1mpi, real colvector pivec,
              real scalar maxflips, real scalar sigupper)
{
    real scalar    Jd, j, jj, nflip, lp0, lp1, S0, S1, pr, Sg, Nn
    real colvector ordr, g0, g1, idx, xb, ob, btil, bs
    real matrix    Omg, Vinv, Vch

    Jd = rows(g)
    Nn = nu + n

    ordr = (1::Jd)
    ordr = ordr[order(runiform(Jd, 1), 1)]

    nflip = Jd
    if (maxflips > 0 & maxflips < Jd) {
        nflip = maxflips
    }

    for (jj = 1; jj <= nflip; jj++) {
        j = ordr[jj]
        if (pivec[j] >= 1) {
            g[j] = 1
            continue
        }
        if (pivec[j] <= 0) {
            g[j] = 0
            continue
        }
        g0 = g
        g1 = g
        g0[j] = 0
        g1[j] = 1
        S0 = .
        S1 = .
        lp0 = _ci_logmarg(g0, XtX, Xty, yty, Om, bpr, nu, seps, n, logpi, log1mpi, S0)
        lp1 = _ci_logmarg(g1, XtX, Xty, yty, Om, bpr, nu, seps, n, logpi, log1mpi, S1)
        if (lp0 >= . & lp1 >= .) {
            continue
        }
        if (lp1 >= .) {
            g[j] = 0
            continue
        }
        if (lp0 >= .) {
            g[j] = 1
            continue
        }
        if (lp0 > lp1) {
            pr = exp(lp1 - lp0)/(1 + exp(lp1 - lp0))
        }
        else {
            pr = 1/(1 + exp(lp0 - lp1))
        }
        g[j] = (runiform(1, 1) < pr)
    }

    Sg  = .
    lp0 = _ci_logmarg(g, XtX, Xty, yty, Om, bpr, nu, seps, n, logpi, log1mpi, Sg)
    if (Sg >= . | Sg <= 0) {
        Sg = seps + yty
    }

    s2obs = _ci_draw_sig2(Nn, Sg, 0, 0, sigupper)
    if (s2obs >= . | s2obs <= 0) {
        s2obs = Sg/Nn
    }

    beta = J(Jd, 1, 0)
    idx  = selectindex(g :> 0)
    if (length(idx) > 0) {
        Omg  = Om[idx, idx]
        Vinv = XtX[idx, idx] + Omg
        xb   = Xty[idx]
        ob   = Omg*bpr[idx]
        btil = cholsolve(Vinv, xb + ob)
        if (hasmissing(btil)) {
            btil = invsym(Vinv)*(xb + ob)
        }
        Vch = cholesky(invsym(Vinv))
        if (hasmissing(Vch)) {
            Vch = J(length(idx), length(idx), 0)
        }
        bs = btil + sqrt(s2obs)*(Vch*rnormal(length(idx), 1, 0, 1))
        beta[idx] = bs
    }
}

// -------------------------------------------------------------------------
// Ports of PrettifyNumber() / PrettifyPercentage() for the verbal report.
// -------------------------------------------------------------------------
string scalar _ci_prettynum(real scalar x, string scalar letter, real scalar rd)
{
    real scalar fz, ax
    if (x >= .) {
        return("NA")
    }
    ax = abs(x)
    if ((letter == "" & ax >= 1e9) | letter == "B") {
        return(strtrim(strofreal(x/1e9, "%30." + strofreal(rd) + "f")) + "B")
    }
    if ((letter == "" & ax >= 1e6) | letter == "M") {
        return(strtrim(strofreal(x/1e6, "%30." + strofreal(rd) + "f")) + "M")
    }
    if ((letter == "" & ax >= 1e3) | letter == "K") {
        return(strtrim(strofreal(x/1e3, "%30." + strofreal(rd) + "f")) + "K")
    }
    if (ax >= 1 | x == 0) {
        return(strtrim(strofreal(x, "%30." + strofreal(rd) + "f")))
    }
    fz = -floor(log10(ax))
    return(strtrim(strofreal(x, "%30." + strofreal(rd + fz - 1) + "f")))
}

string scalar _ci_letterof(string scalar s)
{
    string scalar c
    c = substr(s, strlen(s), 1)
    if (c == "B" | c == "M" | c == "K") {
        return(c)
    }
    return("")
}

string scalar _ci_prettypct(real scalar x)
{
    string scalar s
    s = strtrim(strofreal(100*x, "%30.0f"))
    if (100*x >= 0) {
        s = "+" + s
    }
    return(s + "%")
}

void _ci_report_strings(real scalar digits)
{
    real matrix   S
    string scalar L1, L2, a1, a2
    S  = st_matrix("e(summary)")
    a1 = _ci_prettynum(S[1,1], "", digits)
    a2 = _ci_prettynum(S[2,1], "", digits)
    L1 = _ci_letterof(a1)
    L2 = _ci_letterof(a2)
    st_local("r_act1",    a1)
    st_local("r_act2",    a2)
    st_local("r_pred1",   _ci_prettynum(S[1,2],  L1, 2))
    st_local("r_pred2",   _ci_prettynum(S[2,2],  L2, 2))
    st_local("r_predlo1", _ci_prettynum(S[1,3],  L1, digits))
    st_local("r_predlo2", _ci_prettynum(S[2,3],  L2, digits))
    st_local("r_predup1", _ci_prettynum(S[1,4],  L1, digits))
    st_local("r_predup2", _ci_prettynum(S[2,4],  L2, digits))
    st_local("r_abs1",    _ci_prettynum(S[1,6],  L1, digits))
    st_local("r_abs2",    _ci_prettynum(S[2,6],  L2, digits))
    st_local("r_abslo1",  _ci_prettynum(S[1,7],  L1, digits))
    st_local("r_absup1",  _ci_prettynum(S[1,8],  L1, digits))
    st_local("r_rel1",    _ci_prettypct(S[1,10]))
    st_local("r_rello1",  _ci_prettypct(S[1,11]))
    st_local("r_relup1",  _ci_prettypct(S[1,12]))
}

// -------------------------------------------------------------------------
// Small helpers
// -------------------------------------------------------------------------
real scalar _ci_firstge(real colvector tv, real scalar val)
{
    real scalar i
    for (i = 1; i <= rows(tv); i++) {
        if (tv[i] >= val) {
            return(i)
        }
    }
    return(.)
}

real scalar _ci_lastle(real colvector tv, real scalar val)
{
    real scalar i, k
    k = .
    for (i = 1; i <= rows(tv); i++) {
        if (tv[i] <= val) {
            k = i
        }
    }
    return(k)
}

real scalar _ci_illcond(real colvector y)
{
    real colvector nz
    nz = select(y, y :< .)
    if (length(nz) < 3) {
        return(1)
    }
    if (sqrt(variance(nz)) <= 0) {
        return(1)
    }
    return(0)
}

real scalar _ci_sdcol(real colvector x)
{
    real colvector nz
    real scalar    s
    nz = select(x, x :< .)
    if (length(nz) < 2) {
        return(1)
    }
    s = sqrt(variance(nz))
    if (s <= 0 | s >= .) {
        return(1)
    }
    return(s)
}

// -------------------------------------------------------------------------
//                              MAIN DRIVER
// -------------------------------------------------------------------------
void _ci_main()
{
    struct cissm scalar M

    external real matrix    _causalimpact_series
    external real colvector _causalimpact_rows

    real colvector idx, tv, yorig, ymod, keeprow, yfit, yobs, obsi, obsi2
    real colvector mu_c, sd_c, RQRd, yker, mucon, regcon, ydot, Xtyf
    real colvector bpr, pivec, logpi, log1mpi, gam, beta, sobs_d, slev_d
    real colvector ssea_d, sbet_d, pmean, plo, pup, cpred, cplo, cpup, cumy
    real colvector post_idx, ypost, rmean, rsum, dmean, dsum, relc
    real colvector pe, pel, peu, ce, cel, ceu, ae, rows_full, bmean
    real colvector Tadv1, a1v, advv, gj, bj, bnz, s2bet, dynsum, dynn
    real matrix    X, Xmod, Xd, Xobs, Zmat, alpha_t, statesam, ysam
    real matrix    betasam, gamsam, cumsam, XtXf, Om, SUM, BB, VV, INCL
    real matrix    bdev, Tadv, Thold, P1m
    string scalar  tousev, depv
    string rowvector covn, xnames

    real scalar n, i, j, t, m, nx, hasx, d, dss, Jd, ndraw, keep, it, kk
    real scalar pre1, pre2, post1, post2, i_pre1, i_pre2, i_post1, i_post2
    real scalar r_pre2, r_post1, r_post2, nobs, np
    real scalar niter, burnin, alpha, plevsd, S, dur, dynreg, stdz, addcon
    real scalar maxflips, msize, r2, pdf, ginfo, dshr, sigupper, dots, dotev
    real scalar ymu, ysd, sdy, s2obs, s2lev, s2seas, mj, sj, sxj
    real scalar dlev, sslev, uplev, dsea, sssea, upsea, dobs, ssobs, upobs
    real scalar dbet, upbet, nueps, seps, statreg, sumsq, nsum, eta, acc
    real scalar plow, pupp, run, lastc, cacc, col, acc2, sk, ysumobs
    real scalar ymeanobs, predsum_post, predmean_post, cge, cle, pval
    real scalar inpre, inpost, nrun, yty2, y1
    real colvector xj

    // ---------------------------------------------------------------- read
    tousev = st_local("touse")
    idx    = selectindex(st_data(., tousev) :!= 0)
    n      = length(idx)

    depv = st_local("depvar")
    covn = tokens(st_local("covars"))
    nx    = cols(covn)
    hasx = (nx > 0)

    tv    = st_data(idx, st_local("tvar"))
    yorig = st_data(idx, depv)
    X     = J(n, 0, 0)
    if (hasx) {
        X = st_data(idx, covn)
    }

    niter    = strtoreal(st_local("niter"))
    burnin   = strtoreal(st_local("burnin"))
    alpha    = strtoreal(st_local("alpha"))
    plevsd   = strtoreal(st_local("priorlevelsd"))
    S        = strtoreal(st_local("nseasons"))
    dur      = strtoreal(st_local("seasonduration"))
    dynreg   = strtoreal(st_local("dynreg"))
    stdz     = strtoreal(st_local("stdz"))
    addcon   = strtoreal(st_local("addcon"))
    maxflips = strtoreal(st_local("maxflips"))
    msize    = strtoreal(st_local("modelsize"))
    r2       = strtoreal(st_local("r2"))
    pdf      = strtoreal(st_local("priordf"))
    ginfo    = strtoreal(st_local("ginfo"))
    dshr     = strtoreal(st_local("dshrinkage"))
    sigupper = strtoreal(st_local("sigmaupper"))
    dots     = strtoreal(st_local("dots"))
    pre1     = strtoreal(st_local("pre1"))
    pre2     = strtoreal(st_local("pre2"))
    post1    = strtoreal(st_local("post1"))
    post2    = strtoreal(st_local("post2"))
    if (sigupper < 0) {
        sigupper = .
    }

    // ---------------------------------------------------------------- S1
    i_pre1  = _ci_firstge(tv, pre1)
    i_pre2  = _ci_lastle(tv, pre2)
    i_post1 = _ci_firstge(tv, post1)
    i_post2 = _ci_lastle(tv, post2)
    if (i_pre1 >= . | i_pre2 >= . | i_post1 >= . | i_post2 >= .) {
        st_local("e_ci_ok", "0")
        st_local("e_ci_msg", "each period must cover at least one data point")
        return
    }
    if (i_post2 > n) {
        i_post2 = n
    }

    for (i = 1; i <= n; i++) {
        if (yorig[i] < .) {
            break
        }
    }
    if (i > i_pre1) {
        i_pre1 = i
    }
    if (i_pre2 - i_pre1 < 2) {
        st_local("e_ci_ok", "0")
        st_local("e_ci_msg", "the pre-period must span at least 3 time points")
        return
    }
    if (i_post1 <= i_pre2) {
        st_local("e_ci_ok", "0")
        st_local("e_ci_msg", "the post-period must start after the pre-period ends")
        return
    }

    // ---------------------------------------------------------------- S2
    keeprow = (i_pre1::n)
    m       = length(keeprow)
    ymod    = yorig[keeprow]
    Xmod    = J(m, 0, 0)
    if (hasx) {
        Xmod = X[keeprow, .]
    }
    r_pre2  = i_pre2  - i_pre1 + 1
    r_post1 = i_post1 - i_pre1 + 1
    r_post2 = i_post2 - i_pre1 + 1

    if (_ci_illcond(ymod[1::r_pre2])) {
        st_local("e_ci_ok", "0")
        st_local("e_ci_msg", "the response is constant, all missing, or has fewer than 3 non-missing values in the pre-period")
        return
    }

    ymu  = 0
    ysd  = 1
    mu_c = J(max((nx,1)), 1, 0)
    sd_c = J(max((nx,1)), 1, 1)
    if (stdz) {
        ymu = mean(select(ymod[1::r_pre2], ymod[1::r_pre2] :< .))
        ysd = _ci_sdcol(ymod[1::r_pre2])
        ymod = (ymod :- ymu)/ysd
        if (hasx) {
            for (j = 1; j <= nx; j++) {
                xj = Xmod[., j]
                mj = mean(select(xj[1::r_pre2], xj[1::r_pre2] :< .))
                sj = _ci_sdcol(xj[1::r_pre2])
                Xmod[., j] = (xj :- mj)/sj
                mu_c[j] = mj
                sd_c[j] = sj
            }
        }
    }

    // Design matrix; bsts includes an intercept in the regression component.
    Xd     = Xmod
    xnames = covn
    if (hasx & addcon) {
        Xd     = (Xmod, J(m, 1, 1))
        xnames = (covn, "_cons")
    }
    Jd = cols(Xd)

    // ---------------------------------------------------------------- S3
    yfit = ymod
    for (t = r_pre2 + 1; t <= m; t++) {
        yfit[t] = .
    }
    nobs = 0
    for (t = 1; t <= m; t++) {
        if (yfit[t] < .) {
            nobs = nobs + 1
        }
    }

    sdy = _ci_sdcol(yfit)

    // ---------------------------------------------------------------- S4-S8
    dss = 1
    if (S > 1) {
        dss = S
    }
    d = dss
    if (dynreg) {
        d = dss + Jd
    }

    Tadv  = J(d, d, 0)
    Thold = J(d, d, 0)
    Tadv[1,1]  = 1
    Thold[1,1] = 1
    if (S > 1) {
        for (i = 2; i <= dss; i++) {
            Tadv[2,i] = -1
        }
        for (i = 3; i <= dss; i++) {
            Tadv[i,i-1] = 1
        }
        for (i = 2; i <= dss; i++) {
            Thold[i,i] = 1
        }
    }
    if (dynreg) {
        for (i = dss + 1; i <= d; i++) {
            Tadv[i,i]  = 1
            Thold[i,i] = 1
        }
    }

    advv = J(m, 1, 1)
    if (dur > 1) {
        for (t = 1; t <= m; t++) {
            advv[t] = (mod(t, dur) == 0)
        }
    }

    Zmat = J(d, m, 0)
    for (t = 1; t <= m; t++) {
        Zmat[1,t] = 1
        if (S > 1) {
            Zmat[2,t] = 1
        }
        if (dynreg) {
            for (j = 1; j <= Jd; j++) {
                Zmat[dss + j, t] = Xd[t, j]
            }
        }
    }

    y1 = 0
    for (t = 1; t <= m; t++) {
        if (yfit[t] < .) {
            y1 = yfit[t]
            break
        }
    }
    a1v      = J(d, 1, 0)
    a1v[1]   = y1
    P1m      = I(d)*(sdy*sdy)
    s2bet    = J(max((Jd,1)), 1, 0)
    if (dynreg) {
        for (j = 1; j <= Jd; j++) {
            sxj = _ci_sdcol(Xd[., j])
            P1m[dss + j, dss + j] = (sdy/sxj)^2
            s2bet[j] = (0.01*sdy/sxj)^2
        }
    }

    M.Tadv  = Tadv
    M.Thold = Thold
    M.a1    = a1v
    M.P1    = P1m
    M.adv   = advv
    M.d     = d
    M.S     = S
    M.dur   = dur
    M.m     = m
    M.nx     = Jd
    M.dyn   = dynreg
    M.dss   = dss

    // ---------------------------------------------------------------- S9
    dlev  = 32
    sslev = dlev*(plevsd*sdy)^2
    uplev = sdy

    dsea  = 0.01
    sssea = dsea*(0.01*sdy)^2
    upsea = sdy

    dbet  = 32
    upbet = sdy

    if (dynreg) {
        dobs  = 32
        ssobs = dobs*(plevsd*sdy)^2
        upobs = 0.1*sdy
    }
    else {
        dobs  = 0.01
        ssobs = dobs*(sdy*sdy)
        upobs = 1.2*sdy
    }

    // ---------------------------------------------------------------- S10-S11
    statreg = (hasx & !dynreg)
    gam     = J(max((Jd,1)), 1, 0)
    beta    = J(max((Jd,1)), 1, 0)
    XtXf    = J(1, 1, 0)
    Om      = J(1, 1, 0)
    bpr     = J(max((Jd,1)), 1, 0)
    pivec   = J(max((Jd,1)), 1, 0)
    logpi   = J(max((Jd,1)), 1, 0)
    log1mpi = J(max((Jd,1)), 1, 0)
    nueps   = pdf
    seps    = pdf*(1 - r2)*sdy*sdy

    if (statreg) {
        obsi = selectindex(yfit :< .)
        Xobs = Xd[obsi, .]
        XtXf = quadcross(Xobs, Xobs)
        Om   = (ginfo/nobs)*((1 - dshr)*XtXf + dshr*diag(diagonal(XtXf)))
        for (j = 1; j <= Jd; j++) {
            if (Om[j,j] <= 0) {
                Om[j,j] = 1e-8
            }
        }
        bpr     = J(Jd, 1, 0)
        pivec   = J(Jd, 1, min((1, msize/Jd)))
        logpi   = log(pivec)
        log1mpi = log(1 :- pivec)
        gam     = J(Jd, 1, 1)
        beta    = J(Jd, 1, 0)
    }

    // ---------------------------------------------------------------- init
    s2obs  = (0.1*sdy)^2
    s2lev  = (plevsd*sdy)^2
    s2seas = (0.01*sdy)^2

    ndraw = niter - burnin
    if (ndraw*m > 60000000) {
        st_local("e_ci_ok", "0")
        st_local("e_ci_msg", "the requested MCMC sample is too large for memory; reduce niter() or the sample")
        return
    }

    statesam = J(ndraw, m, 0)
    ysam     = J(ndraw, m, 0)
    betasam  = J(ndraw, max((Jd,1)), 0)
    gamsam   = J(ndraw, max((Jd,1)), 0)
    sobs_d   = J(ndraw, 1, 0)
    slev_d   = J(ndraw, 1, 0)
    ssea_d   = J(ndraw, 1, 0)

    dotev = ceil(niter/50)
    if (dots) {
        printf("{txt}Gibbs sampler: ")
        displayflush()
    }

    keep = 0
    for (it = 1; it <= niter; it++) {

        // ------------------------------------------------------------ S12
        RQRd    = J(d, 1, 0)
        RQRd[1] = s2lev
        if (S > 1) {
            RQRd[2] = s2seas
        }
        if (dynreg) {
            for (j = 1; j <= Jd; j++) {
                RQRd[dss + j] = s2bet[j]
            }
        }

        yker = yfit
        if (statreg) {
            for (t = 1; t <= m; t++) {
                if (yfit[t] < .) {
                    yker[t] = yfit[t] - Xd[t, .]*beta
                }
            }
        }

        alpha_t = _ci_simsmooth(yker, M, Zmat, s2obs, RQRd)

        // ------------------------------------------------------------ S9
        sumsq = 0
        nsum  = 0
        for (t = 1; t <= m - 1; t++) {
            eta   = alpha_t[1, t+1] - alpha_t[1, t]
            sumsq = sumsq + eta*eta
            nsum  = nsum + 1
        }
        s2lev = _ci_draw_sig2(dlev, sslev, nsum, sumsq, uplev)
        if (s2lev >= . | s2lev <= 0) {
            s2lev = (plevsd*sdy)^2
        }

        if (S > 1) {
            sumsq = 0
            nsum  = 0
            for (t = 1; t <= m - 1; t++) {
                if (advv[t] == 1) {
                    eta = alpha_t[2, t+1]
                    for (i = 2; i <= dss; i++) {
                        eta = eta + alpha_t[i, t]
                    }
                    sumsq = sumsq + eta*eta
                    nsum  = nsum + 1
                }
            }
            s2seas = _ci_draw_sig2(dsea, sssea, nsum, sumsq, upsea)
            if (s2seas >= . | s2seas <= 0) {
                s2seas = (0.01*sdy)^2
            }
        }

        if (dynreg) {
            for (j = 1; j <= Jd; j++) {
                sumsq = 0
                nsum  = 0
                for (t = 1; t <= m - 1; t++) {
                    eta   = alpha_t[dss + j, t+1] - alpha_t[dss + j, t]
                    sumsq = sumsq + eta*eta
                    nsum  = nsum + 1
                }
                sxj = _ci_sdcol(Xd[., j])
                s2bet[j] = _ci_draw_sig2(dbet, dbet*(0.01*sdy/sxj)^2, nsum,
                                         sumsq, upbet/sxj)
                if (s2bet[j] >= . | s2bet[j] <= 0) {
                    s2bet[j] = (0.01*sdy/sxj)^2
                }
            }
        }

        // ------------------------------------------------------------ S13
        mucon = J(m, 1, 0)
        for (t = 1; t <= m; t++) {
            mucon[t] = alpha_t[1, t]
            if (S > 1) {
                mucon[t] = mucon[t] + alpha_t[2, t]
            }
        }
        regcon = J(m, 1, 0)
        if (dynreg) {
            for (t = 1; t <= m; t++) {
                acc = 0
                for (j = 1; j <= Jd; j++) {
                    acc = acc + Xd[t, j]*alpha_t[dss + j, t]
                }
                regcon[t] = acc
            }
        }

        if (statreg) {
            ydot = J(m, 1, .)
            for (t = 1; t <= m; t++) {
                if (yfit[t] < .) {
                    ydot[t] = yfit[t] - mucon[t]
                }
            }
            obsi2 = selectindex(ydot :< .)
            Xtyf  = quadcross(Xd[obsi2, .], ydot[obsi2])
            yty2  = quadcross(ydot[obsi2], ydot[obsi2])
            _ci_ssvs(gam, beta, s2obs, XtXf, Xtyf, yty2, Om, bpr, nueps, seps,
                     nobs, logpi, log1mpi, pivec, maxflips, sigupper)
            regcon = Xd*beta
        }
        else {
            sumsq = 0
            nsum  = 0
            for (t = 1; t <= m; t++) {
                if (yfit[t] < .) {
                    eta   = yfit[t] - mucon[t] - regcon[t]
                    sumsq = sumsq + eta*eta
                    nsum  = nsum + 1
                }
            }
            s2obs = _ci_draw_sig2(dobs, ssobs, nsum, sumsq, upobs)
            if (s2obs >= . | s2obs <= 0) {
                s2obs = sumsq/max((nsum, 1))
            }
        }

        // ------------------------------------------------------------ S14
        if (it > burnin) {
            keep = keep + 1
            for (t = 1; t <= m; t++) {
                statesam[keep, t] = mucon[t] + regcon[t]
            }
            ysam[keep, .] = statesam[keep, .] + rnormal(1, m, 0, sqrt(s2obs))
            if (Jd > 0) {
                if (statreg) {
                    betasam[keep, .] = beta'
                    gamsam[keep, .]  = gam'
                }
                if (dynreg) {
                    for (j = 1; j <= Jd; j++) {
                        betasam[keep, j] = mean(alpha_t[dss + j, .]')
                        gamsam[keep, j]  = 1
                    }
                }
            }
            sobs_d[keep] = sqrt(s2obs)
            slev_d[keep] = sqrt(s2lev)
            ssea_d[keep] = sqrt(s2seas)
        }

        if (dots) {
            if (mod(it, dotev) == 0) {
                printf(".")
                displayflush()
            }
        }
    }
    if (dots) {
        printf("{txt} done\n")
        displayflush()
    }

    // -------------------------------------------------- undo S2 before S16
    if (stdz) {
        statesam = statesam*ysd :+ ymu
        ysam     = ysam*ysd :+ ymu
    }
    yobs = yorig[keeprow]

    // ---------------------------------------------------------------- S14
    plow  = alpha/2
    pupp  = 1 - alpha/2
    pmean = J(m, 1, 0)
    plo   = J(m, 1, 0)
    pup   = J(m, 1, 0)
    for (t = 1; t <= m; t++) {
        pmean[t] = mean(statesam[., t])
        plo[t]   = _ci_qcol(ysam[., t], plow)
        pup[t]   = _ci_qcol(ysam[., t], pupp)
    }

    // ---------------------------------------------------------------- S16
    cpred = J(m, 1, .)
    cplo  = J(m, 1, .)
    cpup  = J(m, 1, .)
    cumy  = J(m, 1, .)
    run   = 0
    lastc = 0
    for (t = 1; t <= m; t++) {
        if (yobs[t] < .) {
            run     = run + yobs[t]
            cumy[t] = run
        }
        if (t < r_post1) {
            if (yobs[t] < .) {
                cpred[t] = run
                cplo[t]  = run
                cpup[t]  = run
                lastc    = run
            }
        }
    }
    cumsam = J(ndraw, m - r_post1 + 1, 0)
    for (kk = 1; kk <= ndraw; kk++) {
        acc2 = 0
        col  = 0
        for (t = r_post1; t <= m; t++) {
            col             = col + 1
            acc2            = acc2 + ysam[kk, t]
            cumsam[kk, col] = acc2 + lastc
        }
    }
    cacc = lastc
    col  = 0
    for (t = r_post1; t <= m; t++) {
        col      = col + 1
        cacc     = cacc + pmean[t]
        cpred[t] = cacc
        cplo[t]  = _ci_qcol(cumsam[., col], plow)
        cpup[t]  = _ci_qcol(cumsam[., col], pupp)
    }

    // ---------------------------------------------------------------- S18
    post_idx = (r_post1::r_post2)
    ypost    = yobs[post_idx]
    np       = length(post_idx)
    ysumobs  = quadsum(ypost)
    ymeanobs = ysumobs/np

    rmean = J(ndraw, 1, 0)
    rsum  = J(ndraw, 1, 0)
    dmean = J(ndraw, 1, 0)
    dsum  = J(ndraw, 1, 0)
    relc  = J(ndraw, 1, 0)
    for (kk = 1; kk <= ndraw; kk++) {
        sk        = quadsum(ysam[kk, post_idx])
        rsum[kk]  = sk
        rmean[kk] = sk/np
        dsum[kk]  = ysumobs - sk
        dmean[kk] = ymeanobs - sk/np
        relc[kk]  = ysumobs/sk - 1
    }
    predsum_post  = quadsum(pmean[post_idx])
    predmean_post = predsum_post/np

    SUM = J(2, 15, 0)
    SUM[1,1]  = ymeanobs
    SUM[2,1]  = ysumobs
    SUM[1,2]  = predmean_post
    SUM[2,2]  = predsum_post
    SUM[1,3]  = _ci_qcol(rmean, plow)
    SUM[2,3]  = _ci_qcol(rsum,  plow)
    SUM[1,4]  = _ci_qcol(rmean, pupp)
    SUM[2,4]  = _ci_qcol(rsum,  pupp)
    SUM[1,5]  = sqrt(variance(rmean))
    SUM[2,5]  = sqrt(variance(rsum))
    SUM[1,6]  = ymeanobs - predmean_post
    SUM[2,6]  = ysumobs  - predsum_post
    SUM[1,7]  = _ci_qcol(dmean, plow)
    SUM[2,7]  = _ci_qcol(dsum,  plow)
    SUM[1,8]  = _ci_qcol(dmean, pupp)
    SUM[2,8]  = _ci_qcol(dsum,  pupp)
    SUM[1,9]  = sqrt(variance(dmean))
    SUM[2,9]  = sqrt(variance(dsum))
    // R forces the average and cumulative relative effect to be identical.
    SUM[1,10] = mean(relc)
    SUM[2,10] = mean(relc)
    SUM[1,11] = _ci_qcol(relc, plow)
    SUM[2,11] = _ci_qcol(relc, plow)
    SUM[1,12] = _ci_qcol(relc, pupp)
    SUM[2,12] = _ci_qcol(relc, pupp)
    SUM[1,13] = sqrt(variance(relc))
    SUM[2,13] = sqrt(variance(relc))
    SUM[1,14] = alpha
    SUM[2,14] = alpha

    cge = 1
    cle = 1
    for (kk = 1; kk <= ndraw; kk++) {
        if (rsum[kk] >= ysumobs) {
            cge = cge + 1
        }
        if (rsum[kk] <= ysumobs) {
            cle = cle + 1
        }
    }
    pval      = min((cge, cle))/(ndraw + 1)
    SUM[1,15] = pval
    SUM[2,15] = pval

    st_matrix(st_local("SUM"), SUM)
    st_matrixrowstripe(st_local("SUM"), (J(2,1,""), ("Average" \ "Cumulative")))
    st_matrixcolstripe(st_local("SUM"), (J(15,1,""),
        ("Actual" \ "Pred" \ "Pred_lower" \ "Pred_upper" \ "Pred_sd" \
         "AbsEffect" \ "AbsEffect_lower" \ "AbsEffect_upper" \ "AbsEffect_sd" \
         "RelEffect" \ "RelEffect_lower" \ "RelEffect_upper" \ "RelEffect_sd" \
         "alpha" \ "p")))

    // ------------------------------------------------------------ e(b), e(V)
    if (Jd > 0) {
        bmean = J(Jd, 1, 0)
        for (j = 1; j <= Jd; j++) {
            bmean[j] = mean(betasam[., j])
        }
        bdev = betasam :- bmean'
        BB   = bmean'
        VV   = quadcross(bdev, bdev)/(ndraw - 1)

        INCL = J(Jd, 4, 0)
        for (j = 1; j <= Jd; j++) {
            gj = gamsam[., j]
            bj = betasam[., j]
            INCL[j,1] = mean(gj)
            INCL[j,2] = mean(bj)
            INCL[j,3] = sqrt(variance(bj))
            bnz = select(bj, gj :> 0)
            if (length(bnz) > 0) {
                INCL[j,4] = mean(bnz :> 0)
            }
            else {
                INCL[j,4] = .
            }
        }
        st_matrix(st_local("BB"), BB)
        st_matrix(st_local("VV"), VV)
        st_matrixcolstripe(st_local("BB"), (J(Jd,1,""), xnames'))
        st_matrixcolstripe(st_local("VV"), (J(Jd,1,""), xnames'))
        st_matrixrowstripe(st_local("VV"), (J(Jd,1,""), xnames'))
        st_matrix(st_local("INCL"), INCL)
        st_matrixrowstripe(st_local("INCL"), (J(Jd,1,""), xnames'))
        st_matrixcolstripe(st_local("INCL"), (J(4,1,""),
            ("P_include" \ "PostMean" \ "PostSD" \ "P_positive")))
    }

    // ---------------------------------------------------------------- S15-S17
    rows_full = idx[keeprow]

    st_store(rows_full, st_local("s_resp"),    yobs)
    st_store(rows_full, st_local("s_cumresp"), cumy)
    st_store(rows_full, st_local("s_pred"),    pmean)
    st_store(rows_full, st_local("s_predlo"),  plo)
    st_store(rows_full, st_local("s_predup"),  pup)
    st_store(rows_full, st_local("s_cpred"),   cpred)
    st_store(rows_full, st_local("s_cpredlo"), cplo)
    st_store(rows_full, st_local("s_cpredup"), cpup)

    pe   = J(m, 1, .)
    pel  = J(m, 1, .)
    peu  = J(m, 1, .)
    ce   = J(m, 1, .)
    cel  = J(m, 1, .)
    ceu  = J(m, 1, .)
    ae   = J(m, 1, .)
    nrun = 0
    for (t = 1; t <= m; t++) {
        inpre  = (t <= r_pre2)
        inpost = (t >= r_post1 & t <= r_post2)
        if (inpre | inpost) {
            if (yobs[t] < .) {
                pe[t]  = yobs[t] - pmean[t]              // S15  eq. (2.15)
                pel[t] = yobs[t] - pup[t]
                peu[t] = yobs[t] - plo[t]
            }
            if (cumy[t] < . & cpred[t] < .) {            // S16  eq. (2.16)
                ce[t]  = cumy[t] - cpred[t]
                cel[t] = cumy[t] - cpup[t]
                ceu[t] = cumy[t] - cplo[t]
            }
        }
        if (inpost) {                                    // S17  eq. (2.17)
            nrun = nrun + 1
            if (ce[t] < .) {
                ae[t] = ce[t]/nrun
            }
        }
    }

    st_store(rows_full, st_local("s_eff"),    pe)
    st_store(rows_full, st_local("s_efflo"),  pel)
    st_store(rows_full, st_local("s_effup"),  peu)
    st_store(rows_full, st_local("s_ceff"),   ce)
    st_store(rows_full, st_local("s_cefflo"), cel)
    st_store(rows_full, st_local("s_ceffup"), ceu)
    st_store(rows_full, st_local("s_avgeff"), ae)

    // Keep the series available to causalimpact_p (predict).
    _causalimpact_series = (pmean, plo, pup, cpred, cplo, cpup, pe, pel, peu,
                            ce, cel, ceu, yobs, cumy, ae)
    _causalimpact_rows   = rows_full

    // ---------------------------------------------------------------- out
    st_local("e_ci_N",      strofreal(n))
    st_local("e_ci_npre",   strofreal(i_pre2 - i_pre1 + 1))
    st_local("e_ci_npost",  strofreal(np))
    st_local("e_ci_nmodel", strofreal(m))
    st_local("e_ci_p",      strofreal(pval,      "%20.15g"))
    st_local("e_ci_act1",   strofreal(SUM[1,1],  "%20.15g"))
    st_local("e_ci_act2",   strofreal(SUM[2,1],  "%20.15g"))
    st_local("e_ci_pred1",  strofreal(SUM[1,2],  "%20.15g"))
    st_local("e_ci_pred2",  strofreal(SUM[2,2],  "%20.15g"))
    st_local("e_ci_abs1",   strofreal(SUM[1,6],  "%20.15g"))
    st_local("e_ci_abs2",   strofreal(SUM[2,6],  "%20.15g"))
    st_local("e_ci_abssd1", strofreal(SUM[1,9],  "%20.15g"))
    st_local("e_ci_abssd2", strofreal(SUM[2,9],  "%20.15g"))
    st_local("e_ci_rel1",   strofreal(SUM[1,10], "%20.15g"))
    st_local("e_ci_relsd1", strofreal(SUM[1,13], "%20.15g"))
    st_local("e_ci_sobs",   strofreal(mean(sobs_d)*ysd, "%20.15g"))
    st_local("e_ci_slev",   strofreal(mean(slev_d)*ysd, "%20.15g"))
    st_local("e_ci_sseas",  strofreal(mean(ssea_d)*ysd, "%20.15g"))
}

end
