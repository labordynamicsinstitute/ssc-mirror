*! version 1.0.0  10jun2026  Gorkem Aksaray <aksarayg@tcd.ie>
*! Create indicator variables with automatic variable labels
*!
*! Changelog
*! ---------
*!   [1.0.0]
*!     - Initial public release.

capture program drop dummify
program dummify, rclass
    version 14
    syntax varname [, stub(name local) label(string) ///
        base BASE2(string) force all *]

    confirm numeric variable `varlist'

    if "`base'" != "" & "`base2'" != "" {
        di as err "options {bf:base} and {bf:base()} may not be combined"
        exit 198
    }

    // Defaults: stub and label
    if "`stub'" == "" local stub "`varlist'"

    // If the stub ends in a digit, append "_" so the appended level stays
    // readable (e.g. region1 -> region1_1 rather than the ambiguous region11)
    if regexm("`stub'", "[0-9]$") local stub "`stub'_"

    if `"`label'"' == "" {
        local varlab : variable label `varlist'
        if `"`varlab'"' != "" local label `"`varlab'"'
        else                  local label "`varlist'"
    }

    // Levels of the source variable
    qui levelsof `varlist', local(varlevels)

    if `"`varlevels'"' == "" {
        di as err "{bf:`varlist'} has no non-missing values"
        exit 2000
    }

    // Guardrail: only non-negative integer values are supported, because
    // each level becomes a suffix of a new variable name (e.g. stub`l').
    foreach l of local varlevels {
        if (`l' != int(`l')) | (`l' < 0) {
            di as err `"{bf:`varlist'} contains the value {bf:`l'}"'
            di as err "dummify requires non-negative integer values"
            exit 198
        }
    }

    // Safeguard against accidentally categorizing a near-continuous variable
    local nlev : word count `varlevels'
    if `nlev' > 100 & "`force'" == "" {
        local nlevc = strtrim(string(`nlev', "%15.0fc"))
        di as err "{bf:`varlist'} has `nlevc' distinct levels; this would create `nlevc' indicator variables"
        di as err "specify the {bf:force} option to proceed anyway"
        exit 198
    }

    // Determine the base category (by value)
    if "`base'" != "" {
        local baselevel = word("`varlevels'", 1)
    }
    else if "`base2'" != "" {
        local pos : list posof "`base2'" in varlevels
        if `pos' == 0 {
            di as err "{bf:base(`base2')}: value {bf:`base2'} is not among the levels of {bf:`varlist'}"
            exit 198
        }
        local baselevel "`base2'"
    }

    // Pre-flight: make sure there is room for all the new variables, so the
    // command never starts creating variables it cannot finish.
    local ncreate = `nlev' - ("`baselevel'" != "")
    local room    = c(maxvar) - c(k)
    if `ncreate' > `room' {
        local ncreatec = strtrim(string(`ncreate', "%15.0fc"))
        local roomc    = strtrim(string(`room',    "%15.0fc"))
        local maxvarc  = strtrim(string(c(maxvar), "%15.0fc"))
        di as err "{bf:`varlist'} would require `ncreatec' new indicator variables, but only `roomc' can be added"
        di as err "(the variable limit is `maxvarc'; see {help memory} to raise it with {bf:set maxvar})"
        exit 900
    }

    // Pre-flight: make sure every target name is creatable, so the command
    // is atomic (it never leaves a half-built set of variables behind).
    foreach l of local varlevels {
        if "`l'" == "`baselevel'" continue
        capture confirm new variable `stub'`l'
        if _rc {
            di as err "cannot create variable {bf:`stub'`l''}: the name is invalid or already in use"
            exit _rc
        }
    }

    // Identify the variable's value label (if any). st_vlmap() returns the
    // label for a value, or "" when that value is unlabelled -- something the
    // : label extended function cannot tell us, as it returns the number as a
    // string for unlabelled values.
    local lname : value label `varlist'
    local haslbl = 0
    if "`lname'" != "" mata: st_local("haslbl", strofreal(st_vlexists("`lname'")))

    local anylab = 0
    local stublist ""
    foreach l of local varlevels {
        local tlab_`l' ""
        if `haslbl' mata: st_local("tlab_`l'", st_vlmap("`lname'", `l'))

        if `"`tlab_`l''"' != "" {
            local anylab = 1
            local newvarlab `"`label' = `tlab_`l''"'
        }
        else local newvarlab `"`label' = `l'"'

        if "`l'" == "`baselevel'" {
            local baselevellab `"`newvarlab'"'
            continue
        }

        qui generate byte `stub'`l' = (`varlist' == `l') if !missing(`varlist')
        label variable `stub'`l' `"`newvarlab'"'

        local stublist "`stublist' `stub'`l'"
    }

    if "`stublist'" == "" {
        di as err "no indicator variables were created"
        exit 198
    }

    // Summary of what was created. Columns auto-size to their contents and
    // the table is kept within the current line width, c(linesize); only the
    // variable-length Label column is truncated when it overflows. The Label
    // column is dropped entirely when no level carries a value label. With
    // many levels the middle is collapsed to a single row unless all is given.
    local basemark "(base, omitted)"

    local w_val  = 5
    local w_lab  = 5
    local w_ind  = 9
    foreach l of local varlevels {
        if strlen("`l'") > `w_val' local w_val = strlen("`l'")
        if ustrlen(`"`tlab_`l''"') > `w_lab' local w_lab = ustrlen(`"`tlab_`l''"')
        if "`l'" == "`baselevel'" local ind "`basemark'"
        else                      local ind "`stub'`l'"
        if strlen("`ind'") > `w_ind' local w_ind = strlen("`ind'")
    }

    if `anylab' {
        // 6 = the two 3-character " {c |} " column separators
        local avail = c(linesize) - `w_val' - `w_ind' - 6
        if `avail' < 5 local avail = 5
        if `w_lab' > `avail' local w_lab = `avail'

        di as txt _n %`w_val's "Value" " {c |} " %-`w_lab's "Label" " {c |} " %-`w_ind's "Indicator"
        di as txt "{hline `=`w_val'+1'}{c +}{hline `=`w_lab'+2'}{c +}{hline `=`w_ind'+1'}"
    }
    else {
        di as txt _n %`w_val's "Value" " {c |} " %-`w_ind's "Indicator"
        di as txt "{hline `=`w_val'+1'}{c +}{hline `=`w_ind'+1'}"
    }

    // Rows. With many levels the middle is collapsed to a single divider, but
    // the base category is always shown (pinned) so it is never hidden; a
    // divider is printed only where rows are actually omitted.
    local nshow   = 10
    local doclip  = (`nlev' > 2 * `nshow' + 1 & "`all'" == "")
    local basepos = 0
    if "`baselevel'" != "" local basepos : list posof "`baselevel'" in varlevels

    local i = 0
    local prevshown = 1
    foreach l of local varlevels {
        local ++i
        local shown = (!`doclip') | (`i' <= `nshow') | (`i' > `nlev' - `nshow') | (`i' == `basepos')

        if !`shown' {
            if `prevshown' {
                if `anylab' di as txt %`w_val's ":" " {c |} " %-`w_lab's ":" " {c |} " %-`w_ind's ":"
                else        di as txt %`w_val's ":" " {c |} " %-`w_ind's ":"
            }
            local prevshown = 0
            continue
        }
        local prevshown = 1

        if "`l'" == "`baselevel'" local ind "`basemark'"
        else                      local ind "`stub'`l'"

        if `anylab' {
            local lab `"`tlab_`l''"'
            if ustrlen(`"`lab'"') > `w_lab' {
                local lab = usubstr(`"`lab'"', 1, `w_lab' - 2) + "~" ///
                            + usubstr(`"`lab'"', ustrlen(`"`lab'"'), 1)
            }
            di as txt %`w_val's "`l'" " {c |} " %-`w_lab's `"`lab'"' " {c |} " %-`w_ind's "`ind'"
        }
        else {
            di as txt %`w_val's "`l'" " {c |} " %-`w_ind's "`ind'"
        }
    }

    if `"`options'"' != "" {
        order `stublist', `options'
    }
    else {
        order `stublist', after(`varlist')
    }

    if "`baselevel'" != "" {
        foreach v of local stublist {
            note `v': Base category: `baselevel' (`baselevellab')
        }
    }

    // Stored results
    return scalar k = `: word count `stublist''
    if "`baselevel'" != "" return local base "`baselevel'"
    return local indicators "`stublist'"
    return local varname "`varlist'"
end
