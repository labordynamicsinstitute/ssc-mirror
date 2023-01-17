*! version 1.0.0  16jan2023  Ben Jann
*! helper program for -ipwlogit, vce(svy)-; do not use manually

program _ipwlogit_svy, eclass properties(or svylb svyb svyj)
    version 14
    local version : di "version " string(_caller()) ":"
    gettoken subcmd 0 : 0
    if `"`subcmd'"'=="predict" {
        _ipwlogit_svy_p `0'
        exit
    }
    if `"`subcmd'"'!="estimate" exit 198
    `version' ipwlogit `0'
    eret local cmd "prop" // trick to skip _check_omit
    eret local predict "_ipwlogit_svy predict"
end

program _ipwlogit_svy_p
    version 15
    syntax [anything] [if] [in], [ SCores ]
    _score_spec `anything', ignoreeq
    local vlist `s(varlist)'
    local tlist `s(typlist)'
    capt mata mata describe _IPWLOGIT_TMP_IFs
    if _rc {
        foreach v of local vlist {
            gettoken t tlist : tlist
            qui gen `t' `v' = 0 `if' `in'
        }
        exit
    }
    mata: st_store(., /*
        */ st_addvar(tokens(st_local("tlist")), tokens(st_local("vlist"))), /*
        */ *findexternal("_IPWLOGIT_TMP_IFs"))
    mata mata drop _IPWLOGIT_TMP_IFs
end
