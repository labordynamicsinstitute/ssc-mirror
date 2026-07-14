*! version 1.0.0  12jul2026
program define recode12, rclass
    version 19.5
    syntax [varlist(numeric default=none)] [, YESValue(string) SUFfix(name) REPlace]

    if `"`yesvalue'"' == "" {
        di as err "yesvalue() is required; specify yesvalue(1) or yesvalue(2)"
        exit 198
    }
    if !inlist(`"`yesvalue'"', "1", "2") {
        di as err "yesvalue() must be 1 or 2"
        exit 198
    }

    local suffix_given = (`"`suffix'"' != "")
    if `"`replace'"' != "" & `suffix_given' {
        di as err "suffix() may not be combined with replace"
        exit 198
    }
    if `"`suffix'"' == "" local suffix "_01"

    if `"`varlist'"' == "" {
        quietly ds, has(type numeric)
        local varlist `r(varlist)'
    }
    if `"`varlist'"' == "" {
        di as txt "no numeric variables found"
        return local skipped ""
        return local source ""
        return local recoded ""
        return local value_label ""
        return local status_variable ""
        return scalar yesvalue = `yesvalue'
        return scalar verified = 0
        return scalar n_recoded = 0
        exit
    }

    local eligible
    local skipped
    quietly foreach v of local varlist {
        count if !inlist(`v', 1, 2, .)
        local bad = r(N)
        count if `v' == 1
        local n1 = r(N)
        count if `v' == 2
        local n2 = r(N)
        if (`bad' == 0 & `n1' > 0 & `n2' > 0) {
            local eligible `eligible' `v'
        }
        else {
            local skipped `skipped' `v'
        }
    }

    if `"`eligible'"' == "" {
        di as txt "no variables met the 1/2 coding rule"
        return local skipped `"`skipped'"'
        return local source ""
        return local recoded ""
        return local value_label ""
        return local status_variable ""
        return scalar yesvalue = `yesvalue'
        return scalar verified = 0
        return scalar n_recoded = 0
        exit
    }

    local statusvar "recode12_status"
    capture confirm variable `statusvar'
    if !_rc {
        local statuslabel : variable label `statusvar'
        local statustype : type `statusvar'
        if substr("`statustype'", 1, 3) != "str" | ///
            `"`statuslabel'"' != "recode12 verification status" {
            di as err "variable `statusvar' already exists and was not created by recode12"
            exit 110
        }
    }

    if `"`replace'"' == "" {
        foreach v of local eligible {
            local new `v'`suffix'
            confirm new variable `new'
        }
    }

    local vallab "recode12_NoYes"
    capture quietly label list `vallab'
    if _rc label define `vallab' 0 "No" 1 "Yes"
    else {
        local lab0 : label `vallab' 0
        local lab1 : label `vallab' 1
        if `"`lab0'"' != "No" | `"`lab1'"' != "Yes" {
            di as err "value label `vallab' already exists with incompatible definitions"
            exit 110
        }
    }

    local recoded
    if `yesvalue' == 1 {
        di as txt "mapping: source 1 -> 1 (Yes); source 2 -> 0 (No)"
    }
    else {
        di as txt "mapping: source 1 -> 0 (No); source 2 -> 1 (Yes)"
    }
    foreach v of local eligible {
        local source_vallab : value label `v'
        local cat1
        local cat2
        if `"`source_vallab'"' != "" {
            local cat1 : label `source_vallab' 1
            local cat2 : label `source_vallab' 2
        }
        local target
        if `"`source_vallab'"' != "" {
            if `yesvalue' == 1 local target `"`cat1'"'
            else local target `"`cat2'"'
        }
        if `"`target'"' == "" local target "`v' == `yesvalue'"
        local newvl `"Recoded `target' (0=No; 1=Yes)"'
        local newvl = ustrleft(`"`newvl'"', 80)

        if `"`replace'"' != "" {
            tempvar original
            quietly clonevar `original' = `v'
            quietly replace `v' = (`original' == `yesvalue') if !missing(`original')
            label values `v' `vallab'
            label variable `v' `"`newvl'"'
            if `yesvalue' == 1 {
                assert `v' == 1 if `original' == 1
                assert `v' == 0 if `original' == 2
            }
            else {
                assert `v' == 0 if `original' == 1
                assert `v' == 1 if `original' == 2
            }
            assert `v' == `original' if missing(`original')
            assert inlist(`v', 0, 1) | missing(`v')
            local recoded `recoded' `v'
        }
        else {
            local new `v'`suffix'
            quietly generate byte `new' = (`v' == `yesvalue') if !missing(`v')
            label variable `new' `"`newvl'"'
            label values `new' `vallab'
            if `yesvalue' == 1 {
                assert `new' == 1 if `v' == 1
                assert `new' == 0 if `v' == 2
            }
            else {
                assert `new' == 0 if `v' == 1
                assert `new' == 1 if `v' == 2
            }
            assert `new' == `v' if missing(`v')
            assert inlist(`new', 0, 1) | missing(`new')
            local recoded `recoded' `new'
        }
    }

    capture confirm variable `statusvar'
    if _rc generate str9 `statusvar' = "confirmed"
    else quietly replace `statusvar' = "confirmed"
    label variable `statusvar' "recode12 verification status"

    local n_recoded : word count `recoded'
    di as txt "standardized `n_recoded' variable(s):" as result " `recoded'"
    di as txt "verification passed: all recoded values match the selected mapping rule"
    return local value_label "`vallab'"
    return local status_variable "`statusvar'"
    return scalar yesvalue = `yesvalue'
    return scalar verified = 1
    return local skipped `"`skipped'"'
    return local source `"`eligible'"'
    return local recoded `"`recoded'"'
    return scalar n_recoded = `n_recoded'
end
