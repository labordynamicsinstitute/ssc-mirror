*! version 1.0.0  14mar2024  Ben Jann
*! helper program for -listreg, vce(svy)-; do not use manually

program _listreg_svy, eclass properties(svylb svyb svyj)
    version 14
    local version : di "version " string(_caller()) ":"
    gettoken subcmd 0 : 0
    if `"`subcmd'"'=="predict" {
        _listreg_svy_p `0'
        exit
    }
    if `"`subcmd'"'!="estimate" exit 198
    _parse comma lhs 0 : 0
    syntax [, vce(passthru) * ]
    if `"`vce()'"'!="" {
        di as err "vce() not allowed"
        exit 198
    }
    `version' listreg `lhs'`0'
    eret local cmd "prop" // trick to skip _check_omit
    eret local predict "_listreg_svy predict"
end

program _listreg_svy_p
    version 14
    syntax [anything] [if] [in], [ SCores ]
    _score_spec `anything', ignoreeq
    local vlist `s(varlist)'
    local tlist `s(typlist)'
    capt mata mata describe _LISTREG_TMP_IFs
    if _rc {
        foreach v of local vlist {
            gettoken t tlist : tlist
            qui gen `t' `v' = 0 `if' `in'
        }
        exit
    }
    mata: st_store(., /*
        */ st_addvar(tokens(st_local("tlist")), tokens(st_local("vlist"))), /*
        */ *findexternal("_LISTREG_TMP_IFs"))
    mata mata drop _LISTREG_TMP_IFs
end

