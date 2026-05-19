*! threshcoint.ado -- Master command for the threshcoint Stata package
*! Author: Dr Merwan Roudane
*!
*! Acts as a dispatcher to all individual test/model commands.
*!
*! Syntax:
*!   threshcoint test varlist [, options]
*!   threshcoint model varlist [, options]
*!   threshcoint compare depvar indepvars [, ...]
*!   threshcoint about
*!
*! Allowed tests:
*!   adf, pp, eg, es, glsmtar, exes, covaug, bf, adlbdm, adlbo,
*!   sysadl, supf, hs, kss, bbc
*!
*! Allowed models:
*!   tar, mtar, eqtar, bandtar, rdtar, setar, tvecm

program define threshcoint
    version 14
    if "`1'" == "" {
        threshcoint_help_short
        exit 0
    }
    gettoken what 0 : 0
    if "`what'" == "about" {
        threshcoint_about
        exit 0
    }
    if "`what'" == "compare" {
        tc_compare `0'
        exit 0
    }
    if "`what'" == "test" {
        gettoken test 0 : 0
        local cmdmap_adf       "tc_adf"
        local cmdmap_pp        "tc_pp"
        local cmdmap_eg        "tc_eg"
        local cmdmap_es        "tc_es"
        local cmdmap_glsmtar   "tc_glsmtar"
        local cmdmap_exes      "tc_exes"
        local cmdmap_covaug    "tc_covaug"
        local cmdmap_bf        "tc_bf"
        local cmdmap_adlbdm    "tc_adlbdm"
        local cmdmap_adlbo     "tc_adlbo"
        local cmdmap_sysadl    "tc_sysadl"
        local cmdmap_supf      "tc_supf"
        local cmdmap_hs        "tc_hs"
        local cmdmap_kss       "tc_kss"
        local cmdmap_bbc       "tc_bbc"
        local cmd `cmdmap_`test''
        if "`cmd'" == "" {
            di as error "Unknown test: `test'.  See: threshcoint about"
            exit 198
        }
        `cmd' `0'
        exit 0
    }
    if "`what'" == "model" {
        gettoken model 0 : 0
        local cmdmap_tar     "tc_tar, model(tar)"
        local cmdmap_mtar    "tc_tar, model(mtar)"
        local cmdmap_eqtar   "tc_eqtar, type(eq)"
        local cmdmap_bandtar "tc_eqtar, type(band)"
        local cmdmap_rdtar   "tc_eqtar, type(rd)"
        local cmdmap_setar   "tc_setar"
        local cmdmap_tvecm   "tc_tvecm"
        local cmd `cmdmap_`model''
        if "`cmd'" == "" {
            di as error "Unknown model: `model'.  See: threshcoint about"
            exit 198
        }
        `cmd' `0'
        exit 0
    }
    di as error "Unknown sub-command '`what''. Use: threshcoint test|model|compare|about"
    exit 198
end

program define threshcoint_help_short
    di as text "{hline 72}"
    di as result "  threshcoint" as text " -- Threshold cointegration tests & models (Stata)"
    di as text "{hline 72}"
    di "  threshcoint test {bf:<test>} varlist [, options]"
    di "  threshcoint model {bf:<model>} varlist [, options]"
    di "  threshcoint compare depvar indepvars [, ...]"
    di "  threshcoint about"
    di
    di "  See {bf:help threshcoint} for full documentation."
end

program define threshcoint_about
    di as text "{hline 78}"
    di as result "  threshcoint" as text " -- Threshold cointegration tests & models for Stata"
    di as text "  Author : Dr Merwan Roudane"
    di as text "  Port of the Python " as result "threshcoint" as text " library."
    di as text "{hline 78}"
    di
    di as text "  Tests" as result " (threshcoint test <name>)"
    di "    {bf:adf}      Augmented Dickey-Fuller"
    di "    {bf:pp}       Phillips-Perron"
    di "    {bf:eg}       Engle-Granger cointegration"
    di "    {bf:es}       Enders-Siklos (2001) TAR/MTAR"
    di "    {bf:glsmtar}  Cook (2007) GLS-MTAR"
    di "    {bf:exes}     Extended Enders-Siklos (Osinska & Galecki 2022)"
    di "    {bf:covaug}   Covariates-Augmented (Oh, Lee & Meng 2017)"
    di "    {bf:bf}       Balke-Fomby (1997) sup-Wald"
    di "    {bf:adlbdm}   ADL-BDM (Li & Lee 2010)"
    di "    {bf:adlbo}    ADL-BO  (Li & Lee 2010)"
    di "    {bf:sysadl}   System ADL (Li 2016)"
    di "    {bf:supf}     supF* with structural break (Schweikert 2019)"
    di "    {bf:hs}       Hansen-Seo (2002) supLM"
    di "    {bf:kss}      KSS (2006) nonlinear cointegration"
    di "    {bf:bbc}      BBC (2004) unit root vs SETAR"
    di
    di as text "  Models" as result " (threshcoint model <name>)"
    di "    {bf:tar}      TAR  fit"
    di "    {bf:mtar}     MTAR fit"
    di "    {bf:eqtar}    Equilibrium-TAR (3 regimes)"
    di "    {bf:bandtar}  Band-TAR (alias of EQ-TAR)"
    di "    {bf:rdtar}    Returning-Drift TAR"
    di "    {bf:setar}    SETAR(2)"
    di "    {bf:tvecm}    Threshold VECM (2 regimes)"
    di
    di as text "  Utilities"
    di "    {bf:threshcoint compare}  Run a panel of tests and print comparison table"
    di "    {bf:tc_plot}              Visualize regimes, grid search, ECT"
    di as text "{hline 78}"
end
