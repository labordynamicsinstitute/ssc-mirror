*! version 1.0.1 20aug2022  Ben Jann

program riflogit_p
    version 11
    if `"`e(cmd)'"'!="riflogit" {
        di as err "last riflogit results not found"
        exit 301
    }
    syntax [anything] [if] [in] [, xb stdp Residuals RIF SCores noLABel ]
    local opt `xb' `stdp' `residuals' `scores' `rif'
    if `:list sizeof opt'>1 {
        di as err "only one of xb, stdp, residuals, rif, score allowed"
        exit 198
    }
    if `"`scores'"' != "" {
        _score_spec `anything', scores
        local vname `s(varlist)'
        local vtyp  `s(typlist)'
    }
    else {
        syntax newvarname [if] [in] [, noLABel * ]
        local vname `varlist'
        local vtyp  `typlist'
    }
    if "`residuals'`scores'`rif'"!="" {
        local weight `"`e(wtype)'"'
        if "`weight'"=="pweight" {
            local wgt `"[aweight`e(wexp)']"'
        }
        else if "`weight'"!="" {
            local wgt `"[`weight'`e(wexp)']"'
        }
        tempvar Y RIF
        local depvar `"`e(depvar)'"'
        qui gen byte `Y' = (`depvar'!=0) if `depvar'<.
        riflogit_RIF `Y' `RIF' e(sample) `"`wgt'"'
    }
    if "`opt'"=="residuals" {
        tempvar XB
        qui _predict double `XB'
        gen `vtyp' `vname' = `RIF' - `XB' `if' `in'
        if "`label'"=="" lab var `vname' "Residuals"
        exit
    }
    if "`opt'"=="rif" {
        qui replace `RIF' = . if !e(sample)
        gen `vtyp' `vname' = `RIF' `if' `in'
        if "`label'"=="" lab var `vname' "Recentered influence function"
        exit
    }
    if "`opt'"=="scores" {
        tempvar XB
        qui _predict double `XB'
        gen `vtyp' `vname' = (`RIF' - `XB') / e(rmse)^2 `if' `in'
        if "`label'"=="" lab var `vname' "Score"
        exit
    }
    qui _predict `0' // xb, stdp
end
