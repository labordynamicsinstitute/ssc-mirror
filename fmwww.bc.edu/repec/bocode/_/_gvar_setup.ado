*! _gvar_setup 1.0.1  21aug2026
*! gvar setup -- declare the GVAR: units, time, variable blocks, deterministic
*! case and weight types.  Builds the gvar_MODEL state object.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Step -> source map
*   unit / variable inventory          <- Toolbox gvar.m sections 1.1-1.3
*   endogenous / weakly exogenous flags <- Toolbox create_countrymodels.m
*                                          (dvflag, fvflag, gvflag)
*   deterministic case II / III / IV    <- MacKinnon, Haug & Michelis (1999),
*                                          Toolbox mlcoint.m
*   weight-matrix types per variable    <- Toolbox gvar.m vtypes
*   restriction on weakly exogenous     <- BGVAR expert$Wex.restr

program define _gvar_setup, rclass
    version 14.0

    syntax varlist(numeric) [if] [in] [,          ///
        Unit(varname)                             ///
        Time(varname)                             ///
        GLObal(varlist numeric)                   ///
        GENDog(string)                            ///
        DOMinant(string)                          ///
        FOReign(string)                           ///
        NOForeign(string)                         ///
        EXClude(string)                           ///
        CASe(string)                              ///
        WType(string)                             ///
        PSC(integer 4)                            ///
        SPEC(string)                              ///
        noSUMmary ]

    * -----------------------------------------------------------------------
    * 1.  Identify the panel
    * -----------------------------------------------------------------------
    if ("`unit'" == "" | "`time'" == "") {
        capture qui xtset
        if _rc {
            di as err "specify {bf:unit()} and {bf:time()}, or {bf:xtset} the data first"
            exit 459
        }
        if ("`unit'" == "") local unit "`r(panelvar)'"
        if ("`time'" == "") local time "`r(timevar)'"
    }
    confirm variable `unit'
    confirm numeric variable `time'

    * Do NOT markout on the domestic varlist: in a GVAR a missing series is how
    * "this unit does not have that variable" is encoded, and marking those
    * observations out would delete the whole unit from the model.  Absence is
    * handled below through the dflag matrix, exactly as the Toolbox's
    * create_countrymodels.m does.
    marksample touse, novarlist
    markout `touse' `time'
    capture confirm string variable `unit'
    if (_rc) {
        markout `touse' `unit'
    }
    else {
        qui replace `touse' = 0 if `unit' == ""
    }

    qui count if `touse'
    if (r(N) == 0) {
        di as err "no observations"
        exit 2000
    }

    * -----------------------------------------------------------------------
    * 2.  Unit index and names
    * -----------------------------------------------------------------------
    tempvar uid
    qui egen `uid' = group(`unit') if `touse'
    qui summarize `uid', meanonly
    local N = r(max)
    if (`N' < 2) {
        di as err "a GVAR needs at least two cross-section units"
        exit 459
    }

    local isstr = 0
    capture confirm string variable `unit'
    if (!_rc) local isstr = 1
    local vlab : value label `unit'

    local cnames ""
    forvalues i = 1/`N' {
        if (`isstr') {
            qui levelsof `unit' if `uid' == `i' & `touse', local(nm) clean
        }
        else if ("`vlab'" != "") {
            qui levelsof `unit' if `uid' == `i' & `touse', local(nv) clean
            local nm : label `vlab' `nv'
        }
        else {
            qui levelsof `unit' if `uid' == `i' & `touse', local(nv) clean
            local nm "u`nv'"
        }
        local __gvclong`i' "`nm'"
        local short = strtoname("`nm'")
        local short = subinstr("`short'", "_", "", .)
        if ("`short'" == "") local short "u`i'"
        * keep the short names unique
        local dup : list posof "`short'" in cnames
        if (`dup' > 0) local short "`short'`i'"
        local cnames "`cnames' `short'"
    }
    local cnames = trim("`cnames'")

    * -----------------------------------------------------------------------
    * 3.  Balance check -- the GVAR needs the same T for every unit
    * -----------------------------------------------------------------------
    tempvar nobs
    qui bysort `uid' (`time') : gen long `nobs' = _N if `touse'
    qui summarize `nobs' if `touse'
    if (r(min) != r(max)) {
        di as err "unbalanced panel: units have between " r(min) " and " r(max) " periods"
        di as err "the GVAR requires the same estimation window for every unit"
        exit 459
    }
    local Traw = r(min)
    * (the time values are checked for alignment across units inside Mata,
    *  once the data are sorted unit-major)

    * data frequency, for forecast date labelling
    local tfmt : format `time'
    local freq 1
    if (strpos("`tfmt'", "%tq") > 0) local freq 4
    if (strpos("`tfmt'", "%tm") > 0) local freq 12
    if (strpos("`tfmt'", "%tw") > 0) local freq 52
    if (strpos("`tfmt'", "%td") > 0) local freq 365

    * -----------------------------------------------------------------------
    * 4.  Variable inventory
    * -----------------------------------------------------------------------
    local V : word count `varlist'
    local G : word count `global'

    * ---- weight type per variable, default 1 ------------------------------
    local wtypes ""
    forvalues j = 1/`V' {
        local wtypes "`wtypes' 1"
    }
    if ("`wtype'" != "") {
        foreach pair of local wtype {
            local nm  = substr("`pair'", 1, strpos("`pair'", "=") - 1)
            local val = substr("`pair'", strpos("`pair'", "=") + 1, .)
            local pos : list posof "`nm'" in varlist
            if (`pos' == 0) {
                di as err "wtype(): {bf:`nm'} is not among the domestic variables"
                exit 198
            }
            local wtypes : subinstr local wtypes " " " ", all
            local newl ""
            local k 0
            foreach w of local wtypes {
                local ++k
                if (`k' == `pos') local newl "`newl' `val'"
                else              local newl "`newl' `w'"
            }
            local wtypes = trim("`newl'")
        }
    }

    * ---- deterministic case per unit, default 3 ---------------------------
    local cases ""
    local defcase 3
    if ("`case'" != "") {
        local first : word 1 of `case'
        if (strpos("`first'", "=") == 0) local defcase `first'
    }
    if (!inlist(`defcase', 2, 3, 4)) {
        di as err "case() must be 2, 3 or 4 (MacKinnon-Haug-Michelis)"
        exit 198
    }
    forvalues i = 1/`N' {
        local cases "`cases' `defcase'"
    }
    if ("`case'" != "") {
        foreach pair of local case {
            if (strpos("`pair'", "=") == 0) continue
            local nm  = substr("`pair'", 1, strpos("`pair'", "=") - 1)
            local val = substr("`pair'", strpos("`pair'", "=") + 1, .)
            local pos : list posof "`nm'" in cnames
            if (`pos' == 0) {
                di as err "case(): unknown unit {bf:`nm'}"
                exit 198
            }
            if (!inlist(`val', 2, 3, 4)) {
                di as err "case(): value for {bf:`nm'} must be 2, 3 or 4"
                exit 198
            }
            local newl ""
            local k 0
            foreach c of local cases {
                local ++k
                if (`k' == `pos') local newl "`newl' `val'"
                else              local newl "`newl' `c'"
            }
            local cases = trim("`newl'")
        }
    }

    * -----------------------------------------------------------------------
    * 5.  Build the data blocks and the specification flags in Mata
    * -----------------------------------------------------------------------
    sort `uid' `time'

    * the long names already live in locals __gvclong1..__gvclong`N', so that
    * embedded spaces survive the trip into Mata

    mata: _gvar_do_setup("`varlist'", "`global'", "`touse'", "`uid'",  ///
                         "`time'", `N', `Traw', `freq',               ///
                         "`unit'", "`time'", "`cnames'",              ///
                         "`wtypes'", "`cases'")

    * ---- foreign-counterpart flags ----------------------------------------
    * default: a unit gets the foreign counterpart of each variable it owns
    local forall = 0
    if (lower("`foreign'") == "all") local forall = 1

    mata: _gvar_do_flags(`forall', "`noforeign'", "`exclude'", "`gendog'", "`dominant'")

    * -----------------------------------------------------------------------
    * A full specification grid overrides everything above.  The Toolbox's
    * fvflag matrix is arbitrary -- in the published demo the USA is the only
    * country carrying ep* -- so a grid is the only faithful way to reproduce
    * a published model.  Expected variables:
    *     country, dv_<name>, fv_<name>, gv_<name>, and optionally p q dcase rank
    * -----------------------------------------------------------------------
    if (`"`spec'"' != "") {
        _gvar_read_spec `"`spec'"', domestic(`varlist') global(`global') ///
            units(`cnames')
    }

    mata: gvar_setpsc(`psc')
    mata: gvar_specify()

    * -----------------------------------------------------------------------
    * 6.  Report
    * -----------------------------------------------------------------------
    mata: st_local("K", strofreal(gvar_getK()))

    if ("`summary'" != "nosummary") {
        _gvar_setup_report

        if ("`__gvabsent'" != "") {
            di as text "  Variables absent for some units (unit:variable)"
            di as text "  {hline 74}"
            local line "   "
            foreach p of local __gvabsent {
                if (length("`line'`p' ") > 74) {
                    di as text "`line'"
                    local line "   "
                }
                local line "`line'`p'  "
            }
            if (trim("`line'") != "") di as text "`line'"
            di as text "  {hline 74}"
            di ""
        }
        if ("`__gvpartial'" != "") {
            * {err:} markup, not "as err": a warning inside the summary block,
            * which "as err" would print through -quietly-.
            di as text "  {err:Warning: these series are only PARTIALLY" ///
                       " observed and have}"
            di as text "  {err:therefore been dropped from the unit concerned:}"
            di as text "    {err:`__gvpartial'}"
            di as text "  {err:A GVAR variable must span the whole estimation" ///
                       " window.}"
            di ""
        }
    }

    return local absent  "`__gvabsent'"
    return local partial "`__gvpartial'"

    return scalar N     = `N'
    return scalar T     = `Traw'
    return scalar K     = `K'
    return scalar V     = `V'
    return scalar G     = `G'
    return local  units  "`cnames'"
    return local  domestic "`varlist'"
    return local  global "`global'"
    return local  unitvar "`unit'"
    return local  timevar "`time'"
end

* ---------------------------------------------------------------------------
* Read a full specification grid and install it over the defaults
* ---------------------------------------------------------------------------
program define _gvar_read_spec
    version 14.0
    syntax anything(name=fname), domestic(string) global(string) units(string)

    local fname `fname'
    local N : word count `units'
    local V : word count `domestic'
    local G : word count `global'

    preserve
    qui use `"`fname'"', clear
    capture confirm string variable country
    if _rc {
        restore
        di as err "spec(): the grid must contain a string variable {bf:country}"
        exit 198
    }

    tempname DF FF GF PQ
    matrix `DF' = J(`N', `V', 0)
    matrix `FF' = J(`N', `V', 0)
    if (`G' > 0) matrix `GF' = J(`N', `G', 0)
    matrix `PQ' = J(`N', 4, .)

    tempvar rowno
    qui gen long `rowno' = _n

    local nfound 0
    local i 0
    foreach u of local units {
        local ++i
        qui count if country == "`u'"
        if (r(N) == 0) continue
        local ++nfound
        qui levelsof `rowno' if country == "`u'", local(rr)
        local rr : word 1 of `rr'

        local j 0
        foreach v of local domestic {
            local ++j
            capture confirm variable dv_`v'
            if !_rc matrix `DF'[`i', `j'] = dv_`v'[`rr']
            capture confirm variable fv_`v'
            if !_rc matrix `FF'[`i', `j'] = fv_`v'[`rr']
        }
        local g 0
        foreach v of local global {
            local ++g
            capture confirm variable gv_`v'
            if !_rc matrix `GF'[`i', `g'] = gv_`v'[`rr']
        }
        foreach k in p q dcase rank {
            capture confirm variable `k'
            if !_rc {
                if ("`k'" == "p")     matrix `PQ'[`i', 1] = p[`rr']
                if ("`k'" == "q")     matrix `PQ'[`i', 2] = q[`rr']
                if ("`k'" == "dcase") matrix `PQ'[`i', 3] = dcase[`rr']
                if ("`k'" == "rank")  matrix `PQ'[`i', 4] = rank[`rr']
            }
        }
    }
    restore

    if (`nfound' == 0) {
        di as err "spec(): none of the GVAR units were found in the grid"
        exit 459
    }
    if (`nfound' < `N') {
        di as err "spec(): the grid covers only `nfound' of the `N' units"
        exit 459
    }

    if (`G' > 0) {
        mata: _gvar_apply_spec(st_matrix("`DF'"), st_matrix("`FF'"), ///
                               st_matrix("`GF'"), st_matrix("`PQ'"))
    }
    else {
        mata: _gvar_apply_spec(st_matrix("`DF'"), st_matrix("`FF'"), ///
                               J(`N', 0, 0), st_matrix("`PQ'"))
    }
    di as text "Specification grid read from " as result `"`fname'"' as text "."
end

* ---------------------------------------------------------------------------
program define _gvar_setup_report
    version 14.0

    tempname CN VN KI KS CS
    mata: st_local("N",  strofreal(gvar_getN()))
    mata: st_local("K",  strofreal(gvar_getK()))
    mata: st_local("T",  strofreal(gvar_getT()))
    mata: st_matrix("`KI'", gvar_getki())
    mata: st_matrix("`KS'", gvar_getksi())
    mata: st_matrix("`CS'", gvar_getcase())
    mata: st_local("cn", invtokens(gvar_getcname()'))

    _gvar_title "GVAR specification"
    di as text "  Cross-section units          " as result %8.0f `N'
    di as text "  Time periods                 " as result %8.0f `T'
    di as text "  Endogenous variables (K)     " as result %8.0f `K'
    di ""
    di as text "  {hline 62}"
    di as text "  Unit" _col(16) "Domestic" _col(30) "Weakly exog." _col(48) "Case"
    di as text "  {hline 62}"
    local i 0
    foreach c of local cn {
        local ++i
        di as text "  " abbrev("`c'", 12) ///
           _col(16) as result %8.0f `=`KI'[`i',1]' ///
           _col(30) as result %8.0f `=`KS'[`i',1]' ///
           _col(48) as result %4.0f `=`CS'[`i',1]'
    }
    di as text "  {hline 62}"
    di as text "  Case 2: restricted intercept, no trend"
    di as text "  Case 3: unrestricted intercept in levels, no trend"
    di as text "  Case 4: unrestricted intercept, restricted trend"
    di ""
    di as text "  Next: {bf:gvar weights} to install the weight matrices,"
    di as text "        then {bf:gvar foreign} to rebuild the star variables."
    di ""
end

* ---------------------------------------------------------------------------
