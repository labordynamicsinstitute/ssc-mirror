*! _gvar_import 1.0.1  21aug2026
*! gvar import -- read a GVAR Toolbox data workbook into the long panel.
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
* Inventory 14 / the data side of the Toolbox interface.
*
* The Toolbox keeps its data one WORKSHEET PER VARIABLE, countries across the
* columns and dates down column A:
*
*     [date_num date_chr] = xlsread(intfname, vnames{1}, 'A2:A65536')
*
* so row 1 is a header of country codes and A2 downwards are the dates.  That
* is the opposite orientation from what every Stata command wants, which is
* one row per (unit, period).  This reads the workbook and turns it round.
*
* Step -> source map
*   one sheet per variable, countries in columns   <- gvar.m:191 xlsread
*   column A is the date, row 1 the country codes  <- 'A2:A65536' and the
*                                                     header row it skips
*   a global variable has ONE data column          <- gvname sheets
*
* What it does NOT do is guess.  A sheet that is missing, a country that
* appears in one variable's sheet and not another's, a date column that will
* not parse -- each is reported with the sheet and column that caused it
* rather than silently dropped, because a GVAR built on a quietly truncated
* panel still estimates and still solves.

program define _gvar_import, rclass
    version 14.0

    syntax using/ [,                            ///
        DOMestic(string)                        ///
        GLObal(string)                          ///
        UNIT(name)                              ///
        TIME(name)                              ///
        SHEETs(string)                          ///
        FREQuency(string)                       ///
        CLEAR                                   ///
        noSUMmary                               ///
    ]

    if ("`domestic'" == "") {
        di as err "domestic() is required: the variables to read, one"
        di as err "worksheet each, as the Toolbox stores them."
        di as err "    {bf:gvar import using gvarFullDemo.xls,}"
        di as err "        {bf:domestic(y Dp eq ep r lr) global(poil pmat pmetal)}"
        exit 198
    }
    if ("`unit'" == "") local unit country
    if ("`time'" == "") local time period

    if ("`clear'" == "") {
        capture describe
        if (_rc == 0 & c(N) > 0) {
            di as err "data in memory would be lost; specify {bf:clear}"
            exit 4
        }
    }

    * frequency: only used to build a Stata date from a running index when the
    * sheet's dates do not parse on their own
    local fq = lower("`frequency'")
    if ("`fq'" == "") local fq quarterly
    if (!inlist("`fq'", "quarterly", "monthly", "yearly", "annual", "none")) {
        di as err "frequency() must be quarterly, monthly, yearly or none"
        exit 198
    }

    local nd : word count `domestic'
    local ng : word count `global'

    tempfile acc
    local built 0
    local ncty 0
    local nper 0
    local badsheet ""

    * =======================================================================
    * Domestic variables: one sheet each, countries across
    * =======================================================================
    foreach v of local domestic {
        local sh "`v'"
        * sheets() renames a sheet whose title is not the variable name,
        * as "variable=sheet" pairs
        foreach pr of local sheets {
            if (strpos("`pr'", "=") == 0) continue
            local lhs = substr("`pr'", 1, strpos("`pr'", "=") - 1)
            local rhs = substr("`pr'", strpos("`pr'", "=") + 1, .)
            if ("`lhs'" == "`v'") local sh "`rhs'"
        }

        capture import excel using `"`using'"', sheet("`sh'") firstrow clear
        if (_rc) {
            local badsheet "`badsheet' `sh'(no sheet)"
            continue
        }
        qui describe
        if (r(N) == 0 | r(k) < 2) {
            local badsheet "`badsheet' `sh'(empty)"
            continue
        }

        * column A is the date; everything else is a country
        unab all : _all
        local datev : word 1 of `all'
        local ctys : list all - datev

        _gvar_imp_date `datev' "`fq'" "`time'"
        local nper = r(nper)

        qui keep `time' `ctys'

        * The wide columns ARE the unit names, with no common stub, so
        * reshape needs one attached first.  -reshape long @- is not valid
        * syntax and fails inside _reshape_df with "nothing found where name
        * expected", which names nothing useful.
        foreach c of local ctys {
            capture rename `c' GvI`c'
            if (_rc) {
                di as err "cannot rename column {bf:`c'} on sheet" ///
                          " {bf:`sh'}: the name is too long once prefixed."
                exit 198
            }
        }
        qui reshape long GvI, i(`time') j(`unit') string
        qui rename GvI `v'
        qui drop if missing(`v') & missing(`time')

        local ++built
        if (`built' == 1) {
            qui save `"`acc'"', replace
        }
        else {
            qui merge 1:1 `unit' `time' using `"`acc'"', nogenerate
            qui save `"`acc'"', replace
        }
    }

    * =======================================================================
    * Global variables: one sheet each, a single data column
    * =======================================================================
    foreach v of local global {
        local sh "`v'"
        foreach pr of local sheets {
            if (strpos("`pr'", "=") == 0) continue
            local lhs = substr("`pr'", 1, strpos("`pr'", "=") - 1)
            local rhs = substr("`pr'", strpos("`pr'", "=") + 1, .)
            if ("`lhs'" == "`v'") local sh "`rhs'"
        }

        capture import excel using `"`using'"', sheet("`sh'") firstrow clear
        if (_rc) {
            local badsheet "`badsheet' `sh'"
            continue
        }
        qui describe
        if (r(N) == 0 | r(k) < 2) {
            local badsheet "`badsheet' `sh'(empty)"
            continue
        }
        unab all : _all
        local datev : word 1 of `all'
        local col   : word 2 of `all'

        _gvar_imp_date `datev' "`fq'" "`time'"
        qui keep `time' `col'
        qui rename `col' `v'

        * a global is the same series for every unit, so it is merged m:1
        tempfile g1
        qui save `"`g1'"', replace
        qui use `"`acc'"', clear
        qui merge m:1 `time' using `"`g1'"', nogenerate
        qui save `"`acc'"', replace
    }

    if (`built' == 0) {
        di as err "no worksheet could be read from"
        di as err `"    `using'"'
        if ("`badsheet'" != "") di as err "tried:`badsheet'"
        di as err "Sheet names must match the variable names, or be given as"
        di as err "{bf:sheets(}{it:var=sheet}[ {it:var=sheet} ...]{bf:)}."
        exit 601
    }

    qui use `"`acc'"', clear
    qui order `unit' `time'
    qui sort `unit' `time'
    qui levelsof `unit', local(clist)
    local ncty : word count `clist'
    qui su `time', meanonly
    local nper = r(max) - r(min) + 1

    * ---- what did NOT come through -----------------------------------------
    * A country present in one sheet and absent from another leaves missing
    * values after the merge.  That is exactly the case that estimates and
    * solves without complaint, so it is counted here.
    local nmiss 0
    local ragged ""
    foreach v of local domestic {
        capture confirm variable `v'
        if (_rc) continue
        qui count if missing(`v')
        if (r(N) > 0) {
            local nmiss = `nmiss' + r(N)
            local ragged "`ragged' `v'(`=r(N)')"
        }
    }

    if ("`summary'" != "nosummary") {
        _gvar_title "GVAR workbook imported"
        di as text "  source " as result `"`using'"'
        di as text "  " as result `built' as text " of " as result `nd' ///
           as text " domestic sheet(s), " as result `ng' ///
           as text " global sheet(s)"
        di as text "  " as result `ncty' as text " units, " ///
           as result `nper' as text " periods, " ///
           as result `=_N' as text " rows"
        di as text "  panel keys: " as result "`unit'" as text " and " ///
           as result "`time'"
        if ("`badsheet'" != "") {
            di as text "  {err:sheets not read:}" as result "`badsheet'"
            di as text "  Give them with {bf:sheets(}{it:var=sheet}{bf:)} if" ///
                       " the worksheet titles"
            di as text "  differ from the variable names."
        }
        if (`nmiss' > 0) {
            di as text "  {err:`nmiss' missing value(s)} after merging:" ///
               as result "`ragged'"
            di as text "  A country in one sheet and not another leaves gaps." ///
                       "  The panel is"
            di as text "  ragged, which {bf:gvar setup} will accept and" ///
                       " {bf:gvar estimate} will"
            di as text "  work around unit by unit -- so check this rather" ///
                       " than the fit."
        }
        else {
            di as text "  No missing values: every unit appears in every sheet."
        }
        di ""
        di as text "  Next: {bf:gvar setup} `domestic', unit(`unit')" ///
                   " time(`time')"
        if (`ng' > 0) di as text "        plus global(`global')"
        di ""
    }

    return scalar nunits   = `ncty'
    return scalar nperiods = `nper'
    return scalar nsheets  = `built'
    return scalar nmissing = `nmiss'
    return local  units    "`clist'"
    return local  notread  "`badsheet'"
end

* ---------------------------------------------------------------------------
* Column A into a Stata date.
*
* The Toolbox writes dates in whatever form Excel gave it: a real Excel serial
* number, a string like 1979Q2, or a plain running index.  Rather than guess
* once and be wrong for the rest of the file, each form is tried and the one
* that parses every row wins.  A column that parses only partly is refused --
* a half-parsed date column silently reorders the panel.
* ---------------------------------------------------------------------------
program define _gvar_imp_date, rclass
    version 14.0
    args datev fq time

    qui count
    local N = r(N)

    tempvar t
    qui gen double `t' = .

    * 1. already numeric and plausibly a Stata date or a running index
    capture confirm numeric variable `datev'
    if (!_rc) {
        qui replace `t' = `datev'
    }
    else {
        * 2. a string: try the Toolbox's own YYYYQn / YYYYMnn forms first
        if ("`fq'" == "quarterly") {
            qui gen double `t'q = quarterly(`datev', "YQ")
            qui replace `t' = `t'q
            qui drop `t'q
        }
        else if ("`fq'" == "monthly") {
            qui gen double `t'm = monthly(`datev', "YM")
            qui replace `t' = `t'm
            qui drop `t'm
        }
        else if ("`fq'" == "yearly" | "`fq'" == "annual") {
            qui gen double `t'y = real(`datev')
            qui replace `t' = `t'y
            qui drop `t'y
        }
        * 3. anything left: a running index in the sheet's own order
        qui count if missing(`t')
        if (r(N) > 0 & r(N) < `N') {
            di as err "the date column parsed for only " ///
               as res `=`N' - r(N)' as err " of " as res `N' as err " rows."
            di as err "A partly parsed date column reorders the panel" ///
                      " silently, so it is"
            di as err "refused.  Use {bf:frequency(none)} to keep the" ///
                      " sheet order instead."
            exit 459
        }
        if (r(N) == `N') {
            qui replace `t' = _n
        }
    }

    qui count if missing(`t')
    if (r(N) > 0) qui replace `t' = _n

    capture drop `time'
    qui gen double `time' = `t'
    if ("`fq'" == "quarterly") format `time' %tq
    if ("`fq'" == "monthly")   format `time' %tm
    if ("`fq'" == "yearly" | "`fq'" == "annual") format `time' %ty

    qui su `time', meanonly
    return scalar nper = r(max) - r(min) + 1
end
