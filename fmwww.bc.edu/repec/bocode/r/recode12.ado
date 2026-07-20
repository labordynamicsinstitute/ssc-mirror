*! version 1.1.0  19jul2026
program define recode12, rclass
    version 19.5
    syntax [varlist(default=none)] [, YESValue(string) SUFfix(name) REPlace DISPlay]

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
        quietly ds
        local varlist `r(varlist)'
    }
    if `"`varlist'"' == "" {
        di as txt "no variables found"
        return local skipped ""
        return local source ""
        return local numeric_source ""
        return local string_source ""
        return local numeric_recoded ""
        return local string_recoded ""
        return local recoded ""
        return local value_label ""
        return local status_variable ""
        return scalar yesvalue = `yesvalue'
        return scalar verified = 0
        return scalar n_numeric_recoded = 0
        return scalar n_string_recoded = 0
        return scalar n_recoded = 0
        exit
    }

    local eligible
    local numeric_eligible
    local string_eligible
    local skipped
    quietly foreach v of local varlist {
        capture confirm numeric variable `v'
        if !_rc {
            count if !inlist(`v', 1, 2, .)
            local bad = r(N)
            count if `v' == 1
            local n1 = r(N)
            count if `v' == 2
            local n2 = r(N)
            if (`bad' == 0 & `n1' > 0 & `n2' > 0) {
                local eligible `eligible' `v'
                local numeric_eligible `numeric_eligible' `v'
            }
            else local skipped `skipped' `v'
        }
        else {
            tempvar normalized sourcecode obsno
            generate strL `normalized' = ustrtrim(`v')
            generate long `obsno' = _n
            summarize `obsno' if !inlist(`normalized', "", "."), meanonly
            if r(N) == 0 {
                local skipped `skipped' `v'
                continue
            }
            local first1 = r(min)
            generate byte `sourcecode' = .
            replace `sourcecode' = 1 if `normalized' == `normalized'[`first1'] & !inlist(`normalized', "", ".")
            summarize `obsno' if !inlist(`normalized', "", ".") & missing(`sourcecode'), meanonly
            if r(N) == 0 {
                local skipped `skipped' `v'
                continue
            }
            local first2 = r(min)
            replace `sourcecode' = 2 if `normalized' == `normalized'[`first2'] & !inlist(`normalized', "", ".")
            count if !inlist(`normalized', "", ".") & missing(`sourcecode')
            if r(N) == 0 {
                local eligible `eligible' `v'
                local string_eligible `string_eligible' `v'
            }
            else local skipped `skipped' `v'
        }
    }

    if `"`eligible'"' == "" {
        di as txt "no variables met the two-category coding rule"
        return local skipped `"`skipped'"'
        return local source ""
        return local numeric_source ""
        return local string_source ""
        return local numeric_recoded ""
        return local string_recoded ""
        return local recoded ""
        return local value_label ""
        return local status_variable ""
        return scalar yesvalue = `yesvalue'
        return scalar verified = 0
        return scalar n_numeric_recoded = 0
        return scalar n_string_recoded = 0
        return scalar n_recoded = 0
        exit
    }

    local statusvar "recode12_status"
    capture confirm variable `statusvar'
    if !_rc {
        local statuslabel : variable label `statusvar'
        local statustype : type `statusvar'
        if substr("`statustype'", 1, 3) != "str" | ///
            !inlist(`"`statuslabel'"', "recode12 verification status", ///
                "recode12 Verification Status") {
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

    if `yesvalue' == 1 {
        di as txt "mapping rule: source category 1 -> 1 (Yes); source category 2 -> 0 (No)"
    }
    else {
        di as txt "mapping rule: source category 1 -> 0 (No); source category 2 -> 1 (Yes)"
    }

    local recoded
    local numeric_recoded
    local string_recoded
    foreach v of local eligible {
        capture confirm numeric variable `v'
        if !_rc {
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
            local target : subinstr local target `"' "'", all
            local newvl `"Recoded `target' (0=No; 1=Yes)"'
            local newvl = ustrleft(`"`newvl'"', 80)

            if `"`replace'"' != "" {
                tempvar original
                quietly clonevar `original' = `v'
                quietly replace `v' = (`original' == `yesvalue') if !missing(`original')
                label values `v' `vallab'
                label variable `v' `"`newvl'"'
                assert `v' == (`original' == `yesvalue') if !missing(`original')
                assert missing(`v') if missing(`original')
                assert inlist(`v', 0, 1) | missing(`v')
                local recoded `recoded' `v'
                local numeric_recoded `numeric_recoded' `v'
            }
            else {
                local new `v'`suffix'
                quietly generate byte `new' = (`v' == `yesvalue') if !missing(`v')
                label variable `new' `"`newvl'"'
                label values `new' `vallab'
                assert `new' == (`v' == `yesvalue') if !missing(`v')
                assert missing(`new') if missing(`v')
                assert inlist(`new', 0, 1) | missing(`new')
                local recoded `recoded' `new'
                local numeric_recoded `numeric_recoded' `new'
            }
        }
        else {
            tempvar normalized sourcecode obsno
            quietly generate strL `normalized' = ustrtrim(`v')
            quietly generate long `obsno' = _n
            quietly summarize `obsno' if !inlist(`normalized', "", "."), meanonly
            local first1 = r(min)
            quietly generate byte `sourcecode' = .
            quietly replace `sourcecode' = 1 if `normalized' == `normalized'[`first1'] & !inlist(`normalized', "", ".")
            quietly summarize `obsno' if !inlist(`normalized', "", ".") & missing(`sourcecode'), meanonly
            local first2 = r(min)
            quietly replace `sourcecode' = 2 if `normalized' == `normalized'[`first2'] & !inlist(`normalized', "", ".")

            local cat1 = `normalized'[`first1']
            local cat2 = `normalized'[`first2']
            local target `"`cat`yesvalue''"'
            local target : subinstr local target `"' "'", all
            local newvl `"Recoded `target' (0=No; 1=Yes)"'
            local newvl = ustrleft(`"`newvl'"', 80)
            if `"`replace'"' != "" {
                tempvar original newvalue
                quietly clonevar `original' = `v'
                quietly generate byte `newvalue' = (`sourcecode' == `yesvalue') if !missing(`sourcecode')
                quietly order `newvalue', before(`v')
                quietly drop `v'
                quietly rename `newvalue' `v'
                label variable `v' `"`newvl'"'
                label values `v' `vallab'
                assert `v' == (`sourcecode' == `yesvalue') if !missing(`sourcecode')
                assert missing(`v') if missing(`sourcecode')
                assert inlist(`v', 0, 1) | missing(`v')
                local recoded `recoded' `v'
                local string_recoded `string_recoded' `v'
            }
            else {
                local new `v'`suffix'
                quietly generate byte `new' = (`sourcecode' == `yesvalue') if !missing(`sourcecode')
                label variable `new' `"`newvl'"'
                label values `new' `vallab'
                assert `new' == (`sourcecode' == `yesvalue') if !missing(`sourcecode')
                assert missing(`new') if missing(`sourcecode')
                assert inlist(`new', 0, 1) | missing(`new')
                local recoded `recoded' `new'
                local string_recoded `string_recoded' `new'
            }
        }
    }

    capture confirm variable `statusvar'
    if _rc generate str9 `statusvar' = "confirmed"
    else quietly replace `statusvar' = "confirmed"
    label variable `statusvar' "recode12 Verification Status"

    local n_recoded : word count `recoded'
    local n_numeric_recoded : word count `numeric_recoded'
    local n_string_recoded : word count `string_recoded'
    if `"`display'"' != "" {
        di as txt "number of numeric variables standardized: " ///
            as result `n_numeric_recoded'
        if `n_numeric_recoded' > 0 {
            di as txt "names of numeric variables standardized:"
            local detail_line
            local detail_count = 0
            local detail_width = max(20, c(linesize) - 4)
            foreach name of local numeric_recoded {
                local candidate = strtrim("`detail_line' `name'")
                local candidate_length = strlen("`candidate'")
                if `detail_count' > 0 & ///
                    (`detail_count' >= 7 | `candidate_length' > `detail_width') {
                    di as result "    `detail_line'"
                    local detail_line "`name'"
                    local detail_count = 1
                }
                else {
                    local detail_line "`candidate'"
                    local ++detail_count
                }
            }
            if `"`detail_line'"' != "" di as result "    `detail_line'"
        }
        else di as txt "names of numeric variables standardized: " as result "none"

        di as txt "number of string variables standardized: " ///
            as result `n_string_recoded'
        if `n_string_recoded' > 0 {
            di as txt "names of string variables standardized:"
            local detail_line
            local detail_count = 0
            local detail_width = max(20, c(linesize) - 4)
            foreach name of local string_recoded {
                local candidate = strtrim("`detail_line' `name'")
                local candidate_length = strlen("`candidate'")
                if `detail_count' > 0 & ///
                    (`detail_count' >= 7 | `candidate_length' > `detail_width') {
                    di as result "    `detail_line'"
                    local detail_line "`name'"
                    local detail_count = 1
                }
                else {
                    local detail_line "`candidate'"
                    local ++detail_count
                }
            }
            if `"`detail_line'"' != "" di as result "    `detail_line'"
        }
        else di as txt "names of string variables standardized: " as result "none"
    }
    di as txt "verification passed: all recoded values match the selected mapping rule"
    return local value_label "`vallab'"
    return local status_variable "`statusvar'"
    return scalar yesvalue = `yesvalue'
    return scalar verified = 1
    return local skipped `"`skipped'"'
    return local source `"`eligible'"'
    return local numeric_source `"`numeric_eligible'"'
    return local string_source `"`string_eligible'"'
    return local numeric_recoded `"`numeric_recoded'"'
    return local string_recoded `"`string_recoded'"'
    return local recoded `"`recoded'"'
    return scalar n_numeric_recoded = `n_numeric_recoded'
    return scalar n_string_recoded = `n_string_recoded'
    return scalar n_recoded = `n_recoded'
end
