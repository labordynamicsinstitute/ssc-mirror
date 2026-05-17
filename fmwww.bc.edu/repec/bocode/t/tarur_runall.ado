*! tarur_runall.ado — Run the full TARUR battery and tabulate.
*! Calls each test quietly, collects statistics + decisions, prints a summary.

program define tarur_runall, rclass
    version 14.0
    syntax varname(numeric ts) [if] [in], [ ///
        Case(string)         ///
        MAXLags(integer 8)   ///
        LAGMethod(string)    ]

    quietly tarur_init
    if "`case'"      == "" local case      "demeaned"
    if "`lagmethod'" == "" local lagmethod "aic"

    marksample touse
    tempvar tv
    quietly gen double `tv' = `varlist' if `touse'

    di as text "============================================================"
    di as text "  TARUR — Nonlinear Unit Root Test Battery"
    di as text "============================================================"
    di as text "  Series : `varlist'"
    di as text "  Case   : `case'      Max lags : `maxlags'      Method : `lagmethod'"
    di as text "============================================================"

    local tests "KSS Kruse Sollis2009 HuChen Pascalau CuestasGarratt CuestasOrdonez EndersGranger LNV_A Vougas_A HarveyMills_A"

    tempname results
    matrix `results' = J(11, 7, .)
    matrix rownames `results' = `tests'
    matrix colnames `results' = statistic cv1 cv5 cv10 lag r5 r10

    local row = 1

    // 1. KSS
    capture noisily tarur_kss `tv', case(`case') maxlags(`maxlags') lagmethod(`lagmethod') quietly
    if !_rc {
        matrix `results'[`row',1] = r(stat)
        matrix `results'[`row',2] = r(cv1)
        matrix `results'[`row',3] = r(cv5)
        matrix `results'[`row',4] = r(cv10)
        matrix `results'[`row',5] = r(lag)
        matrix `results'[`row',6] = r(reject5)
        matrix `results'[`row',7] = r(reject10)
    }
    local ++row

    // 2. Kruse
    capture noisily tarur_kruse `tv', case(`case') maxlags(`maxlags') lagmethod(`lagmethod') quietly
    if !_rc {
        matrix `results'[`row',1] = r(stat)
        matrix `results'[`row',2] = r(cv1)
        matrix `results'[`row',3] = r(cv5)
        matrix `results'[`row',4] = r(cv10)
        matrix `results'[`row',5] = r(lag)
        matrix `results'[`row',6] = r(reject5)
        matrix `results'[`row',7] = r(reject10)
    }
    local ++row

    // 3. Sollis2009
    capture noisily tarur_sollis2009 `tv', case(`case') maxlags(`maxlags') lagmethod(`lagmethod') quietly
    if !_rc {
        matrix `results'[`row',1] = r(stat)
        matrix `results'[`row',2] = r(cv1)
        matrix `results'[`row',3] = r(cv5)
        matrix `results'[`row',4] = r(cv10)
        matrix `results'[`row',5] = r(lag)
        matrix `results'[`row',6] = r(reject5)
        matrix `results'[`row',7] = r(reject10)
    }
    local ++row

    // 4. HuChen
    capture noisily tarur_huchen `tv', case(`case') maxlags(`maxlags') lagmethod(`lagmethod') quietly
    if !_rc {
        matrix `results'[`row',1] = r(stat)
        matrix `results'[`row',2] = r(cv1)
        matrix `results'[`row',3] = r(cv5)
        matrix `results'[`row',4] = r(cv10)
        matrix `results'[`row',5] = r(lag)
        matrix `results'[`row',6] = r(reject5)
        matrix `results'[`row',7] = r(reject10)
    }
    local ++row

    // 5. Pascalau
    capture noisily tarur_pascalau `tv', case(`case') maxlags(`maxlags') lagmethod(`lagmethod') quietly
    if !_rc {
        matrix `results'[`row',1] = r(stat)
        matrix `results'[`row',2] = r(cv1)
        matrix `results'[`row',3] = r(cv5)
        matrix `results'[`row',4] = r(cv10)
        matrix `results'[`row',5] = r(lag)
        matrix `results'[`row',6] = r(reject5)
        matrix `results'[`row',7] = r(reject10)
    }
    local ++row

    // 6. CuestasGarratt
    capture noisily tarur_cuestasgarratt `tv', maxlags(`maxlags') lagmethod(`lagmethod') quietly
    if !_rc {
        matrix `results'[`row',1] = r(stat)
        matrix `results'[`row',2] = r(cv1)
        matrix `results'[`row',3] = r(cv5)
        matrix `results'[`row',4] = r(cv10)
        matrix `results'[`row',5] = r(lag)
        matrix `results'[`row',6] = r(reject5)
        matrix `results'[`row',7] = r(reject10)
    }
    local ++row

    // 7. CuestasOrdonez
    capture noisily tarur_cuestasordonez `tv', maxlags(`maxlags') lagmethod(`lagmethod') quietly
    if !_rc {
        matrix `results'[`row',1] = r(stat)
        matrix `results'[`row',2] = r(cv1)
        matrix `results'[`row',3] = r(cv5)
        matrix `results'[`row',4] = r(cv10)
        matrix `results'[`row',5] = r(lag)
        matrix `results'[`row',6] = r(reject5)
        matrix `results'[`row',7] = r(reject10)
    }
    local ++row

    // 8. EndersGranger
    capture noisily tarur_endersgranger `tv', case(`case') maxlags(`maxlags') lagmethod(`lagmethod') quietly
    if !_rc {
        matrix `results'[`row',1] = r(stat)
        matrix `results'[`row',2] = r(cv1)
        matrix `results'[`row',3] = r(cv5)
        matrix `results'[`row',4] = r(cv10)
        matrix `results'[`row',5] = r(lag)
        matrix `results'[`row',6] = r(reject5)
        matrix `results'[`row',7] = r(reject10)
    }
    local ++row

    // 9. LNV Model A
    capture noisily tarur_lnv `tv', model(A) maxlags(`maxlags') lagmethod(`lagmethod') quietly
    if !_rc {
        matrix `results'[`row',1] = r(stat)
        matrix `results'[`row',2] = r(cv1)
        matrix `results'[`row',3] = r(cv5)
        matrix `results'[`row',4] = r(cv10)
        matrix `results'[`row',5] = r(lag)
        matrix `results'[`row',6] = r(reject5)
        matrix `results'[`row',7] = r(reject10)
    }
    local ++row

    // 10. Vougas Model A
    capture noisily tarur_vougas `tv', model(A) maxlags(`maxlags') lagmethod(`lagmethod') quietly
    if !_rc {
        matrix `results'[`row',1] = r(stat)
        matrix `results'[`row',2] = r(cv1)
        matrix `results'[`row',3] = r(cv5)
        matrix `results'[`row',4] = r(cv10)
        matrix `results'[`row',5] = r(lag)
        matrix `results'[`row',6] = r(reject5)
        matrix `results'[`row',7] = r(reject10)
    }
    local ++row

    // 11. Harvey-Mills Model A
    capture noisily tarur_harveymills `tv', model(A) maxlags(`maxlags') lagmethod(`lagmethod') quietly
    if !_rc {
        matrix `results'[`row',1] = r(stat)
        matrix `results'[`row',2] = r(cv1)
        matrix `results'[`row',3] = r(cv5)
        matrix `results'[`row',4] = r(cv10)
        matrix `results'[`row',5] = r(lag)
        matrix `results'[`row',6] = r(reject5)
        matrix `results'[`row',7] = r(reject10)
    }

    di as text "------------------------------------------------------------------------------"
    di as text %-18s "Test" "  " ///
              %10s "Stat"    "  " ///
              %8s  "CV(1%)"  "  " ///
              %8s  "CV(5%)"  "  " ///
              %8s  "CV(10%)" "  " ///
              %4s  "Lag"     "  " ///
              %5s  "R(5%)"   "  " ///
              %5s  "R(10%)"
    di as text "------------------------------------------------------------------------------"
    forvalues r = 1/11 {
        local rn : word `r' of `tests'
        di as result %-18s "`rn'"  "  " ///
                     %10.4f `results'[`r',1]  "  " ///
                     %8.3f  `results'[`r',2]  "  " ///
                     %8.3f  `results'[`r',3]  "  " ///
                     %8.3f  `results'[`r',4]  "  " ///
                     %4.0f  `results'[`r',5]  "  " ///
                     %5.0f  `results'[`r',6]  "  " ///
                     %5.0f  `results'[`r',7]
    }
    di as text "------------------------------------------------------------------------------"
    di as text "  R(5%)/R(10%) = 1 → reject H0 (unit root) at that level."
    di as text "============================================================"

    return matrix results = `results'
end
