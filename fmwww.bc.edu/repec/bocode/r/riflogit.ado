*! version 1.0.1  06jan2023  Ben Jann

program riflogit, eclass properties(or svyr svyb svyj mi)
    version 11
    if replay() {
        Display `0'
        exit
    }
    local version : di "version " string(_caller()) ":"
    _parse_or_opt `0' // returns 00
    `version' _vce_parserun riflogit, mark(CLuster) : `00'
    if "`s(exit)'" != "" {
        ereturn local cmdline `"riflogit `0'"'
        exit
    }
    _riflogit `00' // returns diopts
    eret local cmdline `"riflogit `0'"'
    Display, `diopts'
end

program _parse_or_opt
    // replace option or by eform()
    _parse comma lhs 0 : 0
    syntax [, or eform(passthru) * ]
    if "`or'"!="" {
        if `"`eform'"'=="" {
            local eform eform(Odds ratio)
        }
    }
    c_local 00 `lhs', `eform' `options'
end

program Display
    syntax [, or noHEADer noTABle * ]
    if "`or'"!="" local eform eform(Odds Ratio)
    if "`header'"=="" {
        _coef_table_header
        di ""
    }
    if "`table'"=="" {
        eret display, `eform' `options'
    }
end

program _riflogit, eclass
    syntax varlist(min=1 numeric fv) [if] [in] [pw fw iw] [, ///
        noCONStant Hascons ///
        vce(passthru) Robust hc2 hc3 CLuster(passthru) ///
        eform(passthru) noHEADer noTABle * ]
    
    // collect diopts
    _get_diopts diopts, `options'
    c_local diopts `eform' `header' `table' `diopts'
    
    // process vce
    _parse_vce, `vce' `robust' `hc2' `hc3' `cluster' // returns vce, clustvar
    if `"`vce'"'=="" {
        // use robust SE by default unless iweight
        if "`weight'"!="iweight" {
            local vce vce(robust)
        }
    }
    
    // mark sample
    marksample touse
    if "`clustvar'"!="" {
        markout `touse' `clustvar', strok
    }
    
    // weights
    if "`weight'"=="pweight" {
        local wgt `"[aweight`exp']"'
    }
    else if "`weight'"!="" {
        local wgt `"[`weight'`exp']"'
    }
    
    // generate RIF
    tempvar RIF Y
    gettoken depvar xvars : varlist
    _fv_check_depvar `depvar'
    qui gen byte `Y' = (`depvar'!=0) if `touse'
    riflogit_RIF `Y' `RIF' `touse' `"`wgt'"'
    
    // estimate
    qui regress `RIF' `xvars' [`weight'`exp'] if `touse', depname(`depvar') ///
        `constant' `hascons' `vce'
    eret local cmd "riflogit"
    eret local predict "riflogit_p"
    eret local estat_cmd ""
    eret local title "Unconditional logistic regression "
end

program _parse_vce
    syntax [, vce(str asis) Robust hc2 hc3 CLuster(varname) ]
    // old options
    if "`cluster'"!="" {
        if `"`vce'"'!="" {
            di as err "only one of vce() and cluster() allower"
            exit 198
        }
        local vce cluster `cluster'
    }
    if "`hc2'"!="" {
        if `"`vce'"'!="" {
            di as err "only one of vce() and hc2 allower"
            exit 198
        }
        local vce hc2
    }
    if "`hc3'"!="" {
        if `"`vce'"'!="" {
            di as err "only one of vce() and hc3 allower"
            exit 198
        }
        local vce hc3
    }
    if "`robust'"!="" {
        if `"`vce'"'!="" {
            di as err "only one of vce() and robust allower"
            exit 198
        }
        local vce robust
    }
    // extract clustvar
    gettoken vcetype clustvar : vce
    if `"`vcetype'"'==substr("cluster", 1, max(2,strlen(`"`vcetype'"'))) {
        confirm variable `clustvar'
    }
    else local clustvar
    // return results
    if `"`vce'"'!="" {
        local vce vce(`vce')
    }
    c_local vce `vce'
    c_local clustvar `clustvar'
end
