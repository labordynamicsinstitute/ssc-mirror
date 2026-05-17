*! tarur.ado — Dispatcher for the TARUR Stata library
*! Author: Dr. Merwan Roudane
*!
*! Stata port of the Python TARUR library: nonlinear unit-root,
*! cointegration, and linearity tests with embedded critical values.
*!
*! Usage:
*!   tarur kss            y, case(demeaned) maxlags(8) lagmethod(aic)
*!   tarur kruse          y, ...
*!   tarur sollis2009     y, ...
*!   tarur sollis2004     y, model(A) maxlags(8)
*!   tarur huchen         y, ...
*!   tarur endersgranger  y, ...
*!   tarur lnv            y, model(A) maxlags(8) lagmethod(aic)
*!   tarur vougas         y, model(A) ...
*!   tarur harveymills    y, model(A) ...
*!   tarur cookvougas     y, model(A) ...
*!   tarur kilic          y, ...
*!   tarur parkshintani   y, ...
*!   tarur pascalau       y, ...
*!   tarur cuestasgarratt y, ...
*!   tarur cuestasordonez y, ...
*!   tarur ksscoint       y x,  ...
*!   tarur enderssiklos   y x,  ...
*!   tarur terasvirta     y, d(1)
*!   tarur arch           y, lags(4)
*!   tarur mcleodli       y, lags(12)
*!   tarur runall         y, case(demeaned) maxlags(8)

program define tarur
    version 14.0
    gettoken sub 0 : 0, parse(" ,")
    if "`sub'" == "" {
        di as text "TARUR — Nonlinear Unit Root Testing Library for Stata"
        di as text "Available subcommands:"
        di as text "  kss kruse sollis2009 sollis2004 huchen endersgranger"
        di as text "  lnv vougas harveymills cookvougas kilic parkshintani"
        di as text "  pascalau cuestasgarratt cuestasordonez"
        di as text "  ksscoint enderssiklos"
        di as text "  terasvirta arch mcleodli"
        di as text "  runall"
        di as text "See: help tarur"
        exit 0
    }

    quietly tarur_init

    local sub = lower("`sub'")
    if "`sub'" == "kss" {
        tarur_kss `0'
    }
    else if "`sub'" == "kruse" {
        tarur_kruse `0'
    }
    else if "`sub'" == "sollis2009" {
        tarur_sollis2009 `0'
    }
    else if "`sub'" == "sollis2004" {
        tarur_sollis2004 `0'
    }
    else if "`sub'" == "huchen" {
        tarur_huchen `0'
    }
    else if "`sub'" == "endersgranger" {
        tarur_endersgranger `0'
    }
    else if "`sub'" == "lnv" {
        tarur_lnv `0'
    }
    else if "`sub'" == "vougas" {
        tarur_vougas `0'
    }
    else if "`sub'" == "harveymills" {
        tarur_harveymills `0'
    }
    else if "`sub'" == "cookvougas" {
        tarur_cookvougas `0'
    }
    else if "`sub'" == "kilic" {
        tarur_kilic `0'
    }
    else if "`sub'" == "parkshintani" {
        tarur_parkshintani `0'
    }
    else if "`sub'" == "pascalau" {
        tarur_pascalau `0'
    }
    else if "`sub'" == "cuestasgarratt" {
        tarur_cuestasgarratt `0'
    }
    else if "`sub'" == "cuestasordonez" {
        tarur_cuestasordonez `0'
    }
    else if "`sub'" == "ksscoint" {
        tarur_ksscoint `0'
    }
    else if "`sub'" == "enderssiklos" {
        tarur_enderssiklos `0'
    }
    else if "`sub'" == "terasvirta" {
        tarur_terasvirta `0'
    }
    else if "`sub'" == "arch" {
        tarur_arch `0'
    }
    else if "`sub'" == "mcleodli" {
        tarur_mcleodli `0'
    }
    else if "`sub'" == "runall" {
        tarur_runall `0'
    }
    else {
        di as error "Unknown subcommand `sub'. See help tarur."
        exit 198
    }
end
