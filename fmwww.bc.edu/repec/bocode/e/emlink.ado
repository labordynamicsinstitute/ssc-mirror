*! version 1.0.15  28aug2026
*! emlink -- Probabilistic record linkage (Fellegi-Sunter) with unsupervised EM
*! Author: Mario Anderson Apaza Naupa
*! rioma310@gmail.com
*!
*! IMPORTANT: comparison variables must be NORMALIZED beforehand.
*!            See "help emlink", section Data preparation.

program define emlink, rclass
    version 17.0

    syntax using/ , ///
        IDMaster(varname) ///
        IDUsing(name) ///
        STRvars(string) ///
    [   UBigeo(string)        ///
        BLock(varlist)        ///
        BLOCKUsing(string)    ///
        GENprefix(name)       ///
        Threshold(real -1)    ///
        CLERical(real -1)     ///
        TOLerance(real 1e-10) ///
        MAXiter(integer 3000) ///
        SWAPnames             ///
        SEEDagree(integer 2)  ///
        noWARNings            ///
        clear ]

    /* ============================================================== */
    /* 1. Parse field specifications                                  */
    /* ============================================================== */
    if "`genprefix'" == "" local genprefix _ml

    local K = 0
    local mvars ""
    local uvars ""

    // tolerate "nom = nombre" as well as "nom=nombre"
    local strvars : subinstr local strvars " = " "=", all
    local strvars : subinstr local strvars "= "  "=", all
    local strvars : subinstr local strvars " ="  "=", all
    local ubigeo  : subinstr local ubigeo  " = " "=", all
    local ubigeo  : subinstr local ubigeo  "= "  "=", all
    local ubigeo  : subinstr local ubigeo  " ="  "=", all

    // strvars: "master1=using1 master2 master3=using3 ..."
    foreach pair of local strvars {
        _emlink_split `"`pair'"'
        local mvars "`mvars' `s(lhs)'"
        local uvars "`uvars' `s(rhs)'"
        local ++K
    }
    if "`ubigeo'" != "" {
        _emlink_split `"`ubigeo'"'
        local mvars "`mvars' `s(lhs)'"
        local uvars "`uvars' `s(rhs)'"
        local ++K
    }
    local mvars = strtrim("`mvars'")
    local uvars = strtrim("`uvars'")

    if `K' == 0 {
        di as error "strvars() requires at least one field"
        exit 198
    }

    // blocking: keys in master; blockusing() if named differently there
    local bvarsM "`block'"
    local bvarsU = cond("`blockusing'"=="", "`block'", "`blockusing'")
    local nblock : word count `bvarsM'
    local nblockU : word count `bvarsU'
    if `nblock' != `nblockU' {
        di as error "block() and blockusing() must list the same number of keys"
        exit 198
    }

    /* ============================================================== */
    /* 2. Validate master side                                        */
    /* ============================================================== */
    qui count
    local nA = r(N)
    if `nA' == 0 error 2000

    foreach v of local mvars {
        capture confirm string variable `v'
        if _rc {
            di as error "`v' must exist in the master data and be a string variable"
            di as text  "  (numeric codes such as ubigeo must be stored as strings;"
            di as text  "   use tostring, format() before calling emlink)"
            exit 109
        }
    }

    if "`clear'" == "" {
        di as error "emlink replaces the data in memory with the pair-level results"
        di as text  "  Save your master data first, then specify the {bf:clear} option."
        exit 4
    }

    /* ============================================================== */
    /* 3. Stage master and using files                                */
    /* ============================================================== */
    tempfile masterfile usingfile
    qui save `"`masterfile'"', replace

    preserve
    qui use `"`using'"', clear
    qui count
    local nB = r(N)
    if `nB' == 0 {
        di as error "using file contains no observations"
        exit 2000
    }
    foreach v of local uvars {
        capture confirm string variable `v'
        if _rc {
            di as error "`v' must exist in the using file and be a string variable"
            exit 111
        }
    }
    capture confirm variable `idusing'
    if _rc {
        di as error "idusing() variable `idusing' not found in using file"
        exit 111
    }
    foreach v of local bvarsU {
        capture confirm variable `v'
        if _rc {
            di as error "blocking key `v' not found in using file"
            di as text  "  (use blockusing() if the key has a different name there)"
            exit 111
        }
    }
    qui save `"`usingfile'"', replace
    restore

    /* ============================================================== */
    /* 4. Header and warnings                                         */
    /* ============================================================== */
    di as text ""
    di as text "{hline 72}"
    di as text "emlink " as result "1.0.15" as text ///
       " -- Fellegi-Sunter record linkage (unsupervised EM)"
    di as text "{hline 72}"
    di as text "Master records:      " as result %12.0fc `nA'
    di as text "Using records:       " as result %12.0fc `nB'
    di as text "Comparison fields:   " as result %12.0f  `K'
    di as text "Blocking key(s):     " as result ///
       cond("`bvarsM'"=="", "(none -- full cross product)", "`bvarsM'")
    di as text "Swap-name alignment: " as result ///
       cond("`swapnames'"!="", "on", "off")
    di as text ""

    if `K' < 4 & "`warnings'" != "nowarnings" {
        di as err  "Warning: linking on `K' comparison field(s)."
        di as text "  In an 81-scenario simulation, mean F1 was about 0.94 with"
        di as text "  four fields and 0.90 with three, but fell to about 0.19 with"
        di as text "  two, as homonyms become unidentifiable and recall collapses."
        di as text "  Add a discriminating field (ubigeo, birth year, sex) if you can."
        di as text ""
    }
    if "`bvarsM'" == "" {
        local ncross = `nA' * `nB'
        di as err  "Warning: no blocking; `ncross' candidate pairs will be formed."
        if `ncross' > 5000000 {
            di as text "  This is likely infeasible. Specify block()."
            di as text ""
        }
    }

    /* ============================================================== */
    /* 5. Mata engine                                                 */
    /* ============================================================== */
    // ensure the engine is loaded for this session. Drop any previously
    // loaded engine functions first, so that running emlink several times
    // in one session does not trigger "already exists" on recompile.
    capture findfile emlink_engine.mata
    if _rc {
        di as error "emlink_engine.mata not found on the ado-path"
        di as text  "  Place it in the same folder as emlink.ado."
        exit 601
    }
    capture mata: mata drop emlink_jaccard()
    capture mata: mata drop emlink_tokenset()
    capture mata: mata drop emlink_editsim()
    capture mata: mata drop emlink_level()
    capture mata: mata drop emlink_compare()
    capture mata: mata drop emlink_contrib()
    capture mata: mata drop emlink_estimate_u()
    capture mata: mata drop emlink_seed()
    capture mata: mata drop emlink_em()
    capture mata: mata drop emlink_posterior()
    capture mata: mata drop emlink_weight()
    capture mata: mata drop emlink_calibrate()
    capture mata: mata drop emlink_readid()
    capture mata: mata drop emlink_run()
    quietly run `"`r(fn)'"'

    mata: emlink_run("`masterfile'", "`usingfile'",        ///
                     "`mvars'", "`uvars'",                 ///
                     "`idmaster'", "`idusing'",            ///
                     "`bvarsM'", "`bvarsU'", `K',          ///
                     `tolerance', `maxiter',               ///
                     `threshold', `clerical',              ///
                     ("`swapnames'"!=""), `seedagree',     ///
                     "`genprefix'")

    /* ============================================================== */
    /* 6. Returns  (capture r() BEFORE issuing return statements)     */
    /* ============================================================== */
    local r_pairs = r(n_pairs)
    local r_pat   = r(n_patterns)
    local r_links = r(n_links)
    local r_cler  = r(n_clerical)
    local r_seed  = r(n_seed)
    local r_p     = r(p_match)
    local r_thr   = r(threshold)
    local r_it    = r(iters)
    tempname mP uP
    matrix `mP' = r(m_probs)
    matrix `uP' = r(u_probs)

    return scalar N_master   = `nA'
    return scalar N_using    = `nB'
    return scalar N_fields   = `K'
    return scalar N_pairs    = `r_pairs'
    return scalar N_patterns = `r_pat'
    return scalar N_links    = `r_links'
    return scalar N_clerical = `r_cler'
    return scalar N_seed     = `r_seed'
    return scalar p_match    = `r_p'
    return scalar threshold  = `r_thr'
    return scalar iterations = `r_it'
    return matrix m_probs    = `mP'
    return matrix u_probs    = `uP'
end
