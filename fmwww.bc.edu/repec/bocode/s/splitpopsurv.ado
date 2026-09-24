*! splitpopsurv v1.0.0  22sep2026
*! Split-population (cure / mover-stayer) survival models
*! Author: Nobutaka Fukuda, Tohoku University <nobutaka.fukuda@tohoku.ac.jp>
*!
*! Maximum-likelihood estimation of split-population survival models:
*! an accelerated failure-time regression for event timing among "movers",
*! combined with a logistic regression on the probability of belonging to
*! the immune "stayer" population. Five baseline timing distributions are
*! supported: log-logistic, Weibull, log-normal, gamma, and the generalized
*! gamma that nests the other four.
*!
*! Theory: Schmidt & Witte (1989, J. Econometrics); Yamaguchi (1992, JASA);
*! Yamaguchi & Ferguson (1995, ASR 60(2)); Yamaguchi (1998, Soc. Methodology).
*!
*! IMPORTANT -- correction relative to the widely-circulated Stata `ml`
*! template this command is based on: the original template computes a
*! quantity named "hz2"/"mhz" as (1-p)*hazard_m(t)*survival_m(t), which is
*! algebraically the marginal DENSITY, not the marginal HAZARD (density
*! divided by survival). Plugged into the standard hazard-based likelihood
*! delta*ln(hazard) + ln(survival), that omission double-counts ln(survival)
*! for every observed event. This command implements the corrected
*! log-likelihood, delta*ln(marginal density) + (1-delta)*ln(marginal
*! survival), verified by simulation against known parameters for all five
*! distributions (see splitpopsurv.sthlp for details and the R companion
*! package's manual for the full derivation). With the as-written original
*! formula, ml maximize frequently fails to converge (r(430)) on the same
*! simulated data that converges cleanly and recovers the true parameters
*! under the correction below.

capture program drop splitpopsurv
program define splitpopsurv, eclass
    version 17

    if replay() {
        if "`e(cmd)'" != "splitpopsurv" error 301
        syntax [, Level(cilevel)]
        ml display, level(`level')
        exit
    }

    syntax varlist(min=1 numeric fv) [if] [in], ///
        FAILure(varname numeric)             /// event indicator (1=event, 0=censored)
        CURE(varlist numeric fv)             /// P_regression covariates (cure/stayer logit)
        DISTribution(string)                  /// loglogistic | weibull | lognormal | gamma | ggamma
        [ ///
        GRoup(varname numeric)               /// optional 0/1 flip indicator; default = all 1s
        noCONSTANT                            /// suppress H_regression intercept
        LEVel(cilevel)                        ///
        TECHnique(string)                     /// passed to ml maximize; default bfgs
        ITERate(integer 300)                  ///
        noLOg                                 ///
        DIFficult                             ///
        * ]

    marksample touse
    markout `touse' `failure' `cure'
    if "`group'" != "" markout `touse' `group'

    gettoken depvar indepvars : varlist
    confirm variable `depvar'

    * ---- normalize the distribution() choice ----
    local dist = lower("`distribution'")
    if inlist("`dist'", "ll", "loglogistic", "log-logistic") local dist "loglogistic"
    else if inlist("`dist'", "weib", "weibull")               local dist "weibull"
    else if inlist("`dist'", "lnorm", "lognormal", "log-normal") local dist "lognormal"
    else if inlist("`dist'", "gamma")                          local dist "gamma"
    else if inlist("`dist'", "ggamma", "gengamma", "generalizedgamma") local dist "ggamma"
    else {
        display as error "distribution() must be one of: loglogistic weibull lognormal gamma ggamma"
        exit 198
    }

    if "`technique'" == "" local technique "bfgs"

    * ---- group indicator: default to a constant 1 if not supplied ----
    tempvar grp
    if "`group'" != "" {
        quietly gen byte `grp' = `group' if `touse'
    }
    else {
        quietly gen byte `grp' = 1 if `touse'
    }

    local hrhs "`indepvars'"
    if "`constant'" != "" local hrhs "`hrhs', noconstant"

    quietly count if `touse'
    local nobs = r(N)
    if `nobs' == 0 {
        display as error "no observations"
        exit 2000
    }

    * ================================================================
    * dispatch to the corrected ml-evaluator for the chosen distribution
    * ================================================================
    if "`dist'" == "loglogistic" {
        ml model lf splitpopsurv_lf_loglogistic ///
            (H_regression: `depvar' `failure' `grp' = `hrhs') ///
            (theta2:) ///
            (P_regression: `cure') ///
            if `touse', technique(`technique')
    }
    else if "`dist'" == "weibull" {
        ml model lf splitpopsurv_lf_weibull ///
            (H_regression: `depvar' `failure' `grp' = `hrhs') ///
            (ln_sigma:) ///
            (P_regression: `cure') ///
            if `touse', technique(`technique')
    }
    else if "`dist'" == "lognormal" {
        ml model lf splitpopsurv_lf_lognormal ///
            (H_regression: `depvar' `failure' `grp' = `hrhs') ///
            (ln_sigma:) ///
            (P_regression: `cure') ///
            if `touse', technique(`technique')
    }
    else if "`dist'" == "gamma" {
        ml model lf splitpopsurv_lf_gamma ///
            (H_regression: `depvar' `failure' `grp' = `hrhs') ///
            (kappa:) ///
            (P_regression: `cure') ///
            if `touse', technique(`technique')
        * theta1 is used directly as a rate (no exp() transform) in this
        * distribution and must stay positive -- start at a safe positive
        * constant regardless of covariates, mirroring the R companion
        * package's .safe_start_h(). (silently skipped if noconstant was
        * requested and there is therefore no _cons to initialize)
        capture ml init H_regression:_cons=1
    }
    else if "`dist'" == "ggamma" {
        ml model d0 splitpopsurv_d0_ggamma ///
            (H_regression: `depvar' `failure' `grp' = `hrhs') ///
            (ln_sigma:) ///
            (kappa:) ///
            (P_regression: `cure') ///
            if `touse', technique(`technique')
    }

    ml maximize, level(`level') iterate(`iterate') `log' `difficult' `options'

    ereturn local cmd        "splitpopsurv"
    ereturn local cmdline     `"splitpopsurv `0'"'
    ereturn local distribution "`dist'"
    ereturn local depvar      "`depvar'"
    ereturn local failure     "`failure'"
    ereturn local cure        "`cure'"
    ereturn local groupvar    "`group'"
    ereturn local predict     "splitpopsurv_p"
    ereturn local title       "Split-population survival model (`dist'), corrected likelihood"
end
