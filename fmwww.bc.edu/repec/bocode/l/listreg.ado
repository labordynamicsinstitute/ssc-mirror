*! version 1.0.2  23mar2024  Ben Jann

program listreg, eclass properties(svyb svyj mi)
    version 14
    if replay() {
        Display `0'
        exit
    }
    _parse comma lhs options : 0
    _parse_opts `options' // returns options, vcetype, vcecmd, diopts
    local version : di "version " string(_caller()) ":"
    if "`vcdtype'"=="svyb" {
        `version' `vcecmd': _listreg_svy estimate `lhs'`options'
        _ereturn_svy
    }
    else if "`vcetype'"=="svyr" {
        nobreak {
            capt noisily break {
                `version' `vcecmd': _listreg_svy estimate `lhs'`options'
            }
            if _rc {
                local rc = _rc
                capt mata mata drop _LISTREG_TMP_IFs
                exit `rc'
            }
        }
        _ereturn_svy
    }
    else if "`vcetype'"!="" {
        `version' `vcecmd': `lhs'`options'
    }
    else {
        Estimate `lhs'`options'
    }
    eret local cmdline `"listreg `0'"'
    Display, `diopts'
    if `"`e(ifgenerate)'"'!="" {
        describe `e(ifgenerate)'
    }
end

program _parse_opts
    syntax [, noHEADer Level(passthru) NOSE IFGENerate(passthru) vce(str) * ]
    // display options
    _get_diopts diopts options, `options'
    local diopts `header' `diopts'
    // determine type of VCE
    _parse_opts_vce `vce' // returns vcetype vcearg vcelevel vceopts
    if "`vcetype'"=="" {
        if `"`vce'"'!="" local options vce(`vce') `options'
        local options `nose' `ifgenerate' `options'
        c_local options , `options'
        c_local diopts `level' `diopts'
        exit
    }
    if `"`vcelevel'"'!=""   local level `vcelevel' // vcelevel takes precedence
    else if `"`level'"'!="" local vcelevel `level'
    if "`vcetype'"=="svyr" { // svy linearized
        local options saveifuninmata `ifgenerate' `options'
        local vcecmd svy `vcearg', noheader notable `vcelevel' `vceopts'
    }
    else { // replication-based
        if `"`ifgenerate'"'!="" {
            di as err "{bf:ifgenerate()} not allowed with replication-based VCE"
            exit 198
        }
        local options nose `options'
        if "`vcetype'"=="svyb" { // svy replication-based
            local vcecmd svy `vcearg', noheader notable `vcelevel' `vceopts':
        }
        else { // bootstrap, jackknive
            local options vce(`vce') `options'
            local vcecmd _vce_parserun listreg, wtypes(pw iw) mark(CLuster) /*
                 */ noeqlist `vcetype'opts(noheader notable force)
        }
    }
    local options `level' `options'
    c_local vcetype `vcetype'
    c_local vcecmd  `vcecmd'
    c_local options , `options'
    c_local diopts `level' `diopts'
end

program _parse_opts_vce
    if `"`0'"'=="" exit
    _parse comma vce 0 : 0
    gettoken vce vcearg : vce
    mata: st_local("vcearg", strtrim(st_local("vcearg")))
    if `"`vce'"'=="svy" {
        qui svyset
        if `"`r(settings)'"'==", clear" {
             di as err "data not set up for svy, use {helpb svyset}"
             exit 119
        }
        if `"`vcearg'"'=="" local vcearg `"`r(vce)'"'
        if `"`vcearg'"'== substr("linearized",1,max(3,strlen(`"`vcearg'"'))) /*
            */ local vce svyr
        else   local vce svyb
    }
    else if `"`vce'"'==substr("bootstrap",1,max(4,strlen(`"`vce'"'))) local vce boot
    else if `"`vce'"'==substr("jackknife",1,max(4,strlen(`"`vce'"'))) local vce jk
    else local vce
    syntax [, Level(passthru) * ]
    c_local vcetype  `vce'
    c_local vcearg   `vcearg'
    c_local vcelevel `level'
    c_local vceopts  `options'
end

program _ereturn_svy, eclass
    eret local cmd "listreg"
    eret local cmdname ""
    eret local command ""
    eret local predict ""
end

program Display
    if e(cmd)!="listreg" {
        di as err "last listreg results not found"
        exit 301
    }
    syntax [, noHEADer * ]
    if "`header'"=="" {
        _coef_table_header
        di ""
    }
    eret display, `options'
    local J = e(k_list)
    if `"`e(indepvars)'`e(controls)'`e(controls_1)'`e(controls_2)'"'==""/*
        */ local S 0
    else   local S = e(k_eq)==1
    if `S' {
        local S = `S' + (`"`e(controls_1)'`e(controls_2)'"'!="")
        if `S'==2 local space "  "
    }
    if `J'>1 {
        di as txt "Double-list method:  `space'" as res e(dlmethod)
        di as txt "Outcome variables:   `space'" as res e(depvar)
    }
    di as txt "Long-list indicator: `space'" as res e(tvar)
    forv j = 1/`J' {
        if `J'>1 di as txt "List `j' group sizes:  `space'" _c
        else     di as txt "Group sizes:         `space'" _c
        di as res el(e(_N),`j',1) as txt " in short-list, "/*
        */ as res el(e(_N),`j',2) as txt " in long-list"
    }
    if !`S' exit
    forv j = 1/`S' {
        if `S'>1 {
            local sfx _`j'
            local lbl "Short-list `j' controls: "
        }
        else {
            local sfx
            local lbl "Short-list controls: "
        }
        if `"`e(controls`sfx')'"'=="" {
            local msg `""(empty)""'
        }
        else if strlen(`"`e(controls`sfx')'"')>57 {
            local msg `""{bf:{stata display e(controls`sfx'):e(controls`sfx')}}""'
        }
        else {
            local msg as res e(controls`sfx')
        }
        di as txt "`lbl'" `msg'
    }
end

program Estimate, eclass
    version 14
    
    // syntax
    gettoken ovar_1 0 : 0, parse(" ,")
    gettoken ovar_2 0 : 0, parse(" =,")
    gettoken eq       : 0, parse(" =,")
    if `"`eq'"'=="=" {
        gettoken eq 0 : 0, parse(" =,")
        local ovar `ovar_1' `ovar_2'
        gettoken tvar 0 : 0, parse(" ,")
    }
    else if `"`ovar_2'"'=="=" {
        local ovar `ovar_1'
        gettoken tvar 0 : 0, parse(" ,")
    }
    else {
        local ovar `ovar_1'
        local tvar `ovar_2'
    }
    capt n _parse_ovar `ovar'
    if _rc==1 exit _rc
    if _rc {
        di as err "invalid {it:ovar}"
        exit _rc
    }
    local J: list sizeof ovar
    gettoken ovar_1 ovar_2 : ovar
    gettoken ovar_2        : ovar_2
    capt n _parse_tvar `tvar'
    if _rc==1 exit _rc
    if _rc {
        di as err "invalid {it:tvar}"
        exit _rc
    }
    syntax [varlist(default=none numeric fv)] [if] [in] [pw fw iw] [,/*
        */ noCONStant AEQuations NOIsily AVErage LISTwise CASEwise/*
        */ NOSE vce(passthru) Robust CLuster(passthru) NODFr/*
        */ IFGENerate(str) replace/*
        */ saveifuninmata/* technical option for svy; do not use manually
        */ Level(cilevel)/* (not used)
        */ * ]
    if "`listwise'"!="" local casewise casewise
    if "`noisily'"==""  local qui quietly
    else                local qui
    if "`constant'"!="" {
        if "`varlist'"=="" {
            di as err "{bf:noconstant} not allowed if {it:indepvars} is empty"
            exit 198
        }
    }
    local dl = (`J'==2)
    if `dl' {
        local dl = `dl' + ("`average'"!="")
        _parse_controls 1 options, `options'
        _parse_controls 2, `options'
        if "`controls_2'`znone_2'"=="" {
            local controls_2 `controls_1'
            local zcons_2 `zcons_1'
            local znone_2 `znone_1'
        }
    }
    else {
        local average
        _parse_controls 1, `options'
    }

    // process vce
    _parse_vce, `vce' `robust' `cluster' // returns vceopt, clustvar
    // mark sample and weights
    marksample touse
    markout `touse' `tvar'
    if "`clustvar'"!="" {
        markout `touse' `clustvar', strok
    }
    if `dl' {
        if "`casewise'"=="" {
            forv j = 1/`J' {
                tempvar touse_`j'
                qui gen byte `touse_`j'' = `touse'
                markout `touse_`j'' `ovar_`j'' `controls_`j''
            }
            qui replace `touse' = (`touse_1' | `touse_2')
        }
        else {
            markout `touse' `ovar' `controls_1' `controls_2'
            local touse_1 `touse'
            local touse_2 `touse'
        }
    }
    else {
        markout `touse' `ovar' `controls_1'
        local touse_1 `touse'
    }
    tempvar wvar
    _parse_wvar `wvar' [`weight'`exp'] if `touse'
    if "`wvar'"!="" {
        local wgt  [`weight'=`wvar']
        local iwgt [iw=`wvar'] // for regress
        local awgt [aw=`wvar'] // for _ms_build_info
    }
    _nobs `touse' `wgt' if `touse'
    local N = r(N)
    
    // generate long list indicator
    tempvar T
    qui gen byte `T' = (`tvar')==1 if `touse'
    tempname _N
    mat `_N' = J(`J', 2, .)
    mat rown `_N' = `ovar'
    mat coln `_N' = short-list long-list
    forv j = 1/`J' {
        forv i = 0/1 {
            local tval = (2-`j')==`i'
            capt _nobs `touse_`j'' `wgt' if `T'==`tval'
            if _rc==2000 {
                if `i'==0 local msg "short-list group"
                else      local msg "long-list group"
                if `dl'   local msg "`msg' for {bf:`ovar_`j''}"
                di as err "no observations in `msg'"
                exit 2000
            }
            mat `_N'[`j',`=`i'+1'] = r(N)
        }
    }
    
    // expand factor variables and fill in controls if needed
    fvexpand `varlist' if `touse'
    local xvars `r(varlist)'
    forv j = 1/`J' {
        if "`controls_`j''`znone_`j''"=="" {
            local controls_`j' `varlist'
            local zvars_`j' `xvars'
            local zcons_`j' `constant'
        }
        else if "`znone_`j''"=="" {
            fvexpand `controls_`j'' if `touse_`j''
            local zvars_`j' `r(varlist)'
        }
        else {
            local zvars_`j'
            local zcons_`j'
        }
    }
    
    // generate names of IFs and parse ifgenerate()
    local IF = "`nose'"=="" | "`ifgenerate'`saveifuninmata'"!=""
    if `IF' {
        local k: list sizeof xvars
        if "`constant'"=="" local k = `k' + 1
        forv i = 1/`k' {
            tempname tmp
            local IFb `IFb' `tmp'
        }
        if "`aequations'"!="" {
            if `dl'==2 {
                forv j = 1/2 {
                    forv i = 1/`k' {
                        tempname tmp
                        local IFb_`j' `IFb_`j'' `tmp'
                    }
                }
            }
            forv j = 1/`J' {
                local k: list sizeof zvars_`j'
                if "`zcons_`j''"=="" local k = `k' + 1
                forv i = 1/`k' {
                    tempname tmp
                    local IFc_`j' `IFc_`j'' `tmp'
                }
            }
        }
        local IFs `IFb' `IFb_1' `IFb_2' `IFc_1' `IFc_2'
        if `"`ifgenerate'"'!="" {
            if strpos(`"`ifgenerate'"',"*") {
                gettoken ifstub rest : ifgenerate, parse("* ")
                if `"`rest'"'!="*" {
                    di as err "ifgenerate() invalid; " /*
                        */ "must specify {it:stub}{bf:*} or {it:namelist}"
                    exit 198
                }
                confirm name `ifstub'
                local k: list sizeof IFs
                local ifgenerate
                forv i = 1/`k' {
                    local ifgenerate `ifgenerate' `ifstub'`i'
                }
            }
            confirm names `ifgenerate'
            if "`replace'"=="" {
                confirm new variable `ifgenerate'
            }
        }
    }
    
    // short-list model
    forv j = 1/`J' {
        if `dl' local msg " `j'"
        else    local msg
        `qui' di _n as txt "- short list`msg'"
        tempvar rz_`j' c_`j' invGz_`j'
        `qui' regress `ovar_`j'' `zvars_`j'' `iwgt'/*
            */ if `T'==(`j'-1) & `touse_`j'', `zcons_`j''
        mat `c_`j'' = e(b)
        if `IF' mat `invGz_`j'' = e(V) / e(rmse)^2
        qui predict double `rz_`j'' if `touse_`j'', resid
    }
    if `dl'==1 {
        tempvar touse_p rz
        if "`touse_1'"=="`touse_2'" local touse_p "`touse'"
        else {
            qui gen byte `touse_p' = 0
            qui replace `touse_p' = 1 if `touse_1' & (`T'==1)
            qui replace `touse_p' = 1 if `touse_2' & (`T'==0)
        }
        qui gen double `rz' = cond(`T'==1, `rz_1', `rz_2') if `touse_p'
    }
    else local rz `rz_1'
    
    // long-list model
    if `dl'==2 {
        forv j = 1/`J' {
            `qui' di _n as txt "- residualized long list `j'"
            tempname r_`j' b_`j' invG_`j'
            `qui' regress `rz_`j'' `xvars' `iwgt'/*
                */ if `T'==(2-`j') & `touse_`j'', `constant'
            mat `b_`j'' = e(b)
            if `IF' {
                mat `invG_`j'' = e(V) / e(rmse)^2
                qui predict double `r_`j'' if `touse_`j'', resid
            }
        }
        tempname b
        mat `b' = (`b_1' + `b_2') / 2
    }
    else {
        `qui' di _n as txt "- residualized long list"
        tempname r b invG
        if `dl' local iff `touse_p'
        else    local iff `T'==1 & `touse'
        `qui' regress `rz' `xvars' `iwgt' if `iff', `constant'
        mat `b' = e(b)
        if `IF' {
            mat `invG' = e(V) / e(rmse)^2
            qui predict double `r' if `touse', resid
        }
    }
    
    // put together coefficient vector
    local k = colsof(`b')
    if "`aequations'"!="" {
        mat coleq `b' = "Main"
        if `dl' {
            mat coleq `c_1' = "SL1"
            mat coleq `c_2' = "SL2"
            if `dl'==2 {
                mat coleq `b_1' = "LL1"
                mat coleq `b_2' = "LL2"
                mat `b' = `b', `b_1', `b_2', `c_1', `c_2'
            }
            else {
                mat `b' = `b', `c_1', `c_2'
            }
        }
        else {
            mat coleq `c_1' = "SL"
            mat `b' = `b', `c_1'
        }
    }
    _ms_build_info `b' if `touse' `awgt'
    
    // variance estimation
    if `IF' {
        // compute IFs
        foreach v of local IFs {
            qui gen double `v' = 0 if `touse'
        }
        if `dl'==2 { // averaged double list
            mata: _listreg_IF_avg(1, "`aequations'"!="")
            mata: _listreg_IF_avg(2, "`aequations'"!="")
        }
        else if `dl' { // pooled double list
            mata: _listreg_IF_dl("`aequations'"!="")
        }
        else { // single list
            mata: _listreg_IF_sl("`aequations'"!="")
        }
        
        // compute e(V)
        if "`nose'"=="" {
            tempname V
            `qui' di _n as txt "- variance estimation"
            `qui' total `IFs' `wgt' if `touse', `vceopt'
            local rank = e(rank)
            mat `V' = e(V)
            if "`clustvar'"!="" {
                local Nc = e(N_clust)
                local vce `"`e(vce)'"'
                local vcetype `"`e(vcetype)'"'
            }
            else {
                local Nc = e(N)
                local vce "robust"
                local vcetype "Robust"
            }
            mat coln `V' = `: colfullnames `b''
            mat rown `V' = `: colfullnames `b''
            if "`nodfr'"!="" { // ignore df_r, like GMM
                mat `V' = `V' * ((`Nc'-1) / `Nc')
            }
        }
        if "`saveifuninmata'"!="" {
            mata: *crexternal("_LISTREG_TMP_IFs") = st_data(., st_local("IFs"))
            mata: st_replacematrix(st_local("V"), I(`=colsof(`V')'))
        }
    }
    
    // post results
    eret post `b' `V' [`weight'`exp'], esample(`touse') obs(`N')
    eret local title "List experiment regression"
    eret local cmd "listreg"
    eret local depvar "`ovar'"
    eret local tvar "`tvar'"
    eret local indepvars "`varlist'"
    if `dl' {
        if `dl'==2 eret local dlmethod "average"
        else       eret local dlmethod "pooled"
        if "`controls_1'"=="`controls_2'" {
            eret local controls "`controls_1'"
        }
        else {
            eret local controls_1 "`controls_1'"
            eret local controls_2 "`controls_2'"
        }
    }
    else {
        eret local controls "`controls_1'"
    }
    eret scalar k_list = 1 + (`dl'!=0)
    if "`aequations'"!="" {
        if `dl'==2   eret scalar k_eq = 5
        else if `dl' eret scalar k_eq = 3
        else         eret scalar k_eq = 2
    }
    else eret scalar k_eq = 1
    eret matrix _N = `_N'
    if "`nose'"=="" {
        eret scalar rank = `rank'
        if "`nodfr'"=="" {
            eret scalar df_r = `Nc' - 1
        }
        eret local vce `"`vce'"'
        eret local vcetype `"`vcetype'"'
        if "`clustvar'"!="" {
            eret scalar N_clust = `Nc'
            eret local clustvar "`clustvar'"
        }
        if "`xvars'"!="" { // overall model test
            qui test `xvars'
            if "`nodfr'"!="" eret scalar chi2 = r(chi2)
            else             eret scalar F    = r(F)
            eret scalar df_m = r(df)
            eret scalar p    = r(p)
        }
    }
    
    // generate
    if "`ifgenerate'"!="" {
        local coln: colfullnames e(b)
        foreach v of local ifgenerate {
            gettoken tmp IFs : IFs
            gettoken nm coln: coln
            if "`tmp'"=="" continue, break
            lab var `tmp' "influence function of _b[`nm']"
            capt confirm variable `v', exact
            if _rc==1 exit _rc
            if _rc==0 drop `v'
            rename `tmp' `v'
        }
        eret local ifgenerate "`ifgenerate'"
    }
    
    // noisily
    `qui' di _n as txt "- results"
end

program _parse_ovar
    syntax varlist(max=2 numeric)
    c_local ovar `varlist'
end

program _parse_tvar
    syntax varname(numeric fv)
    c_local tvar `varlist'
end

program _parse_controls
    _parse comma lhs 0 : 0 
    gettoken i lhs : lhs
    gettoken lhs : lhs
    if `"`lhs'"'!="" {
        syntax [, Controls(str) * ]
        c_local `lhs' `options'
    }
    else {
        syntax [, Controls(str) ]
    }
    __parse_controls `controls'
    c_local controls_`i' `controls'
    c_local zcons_`i' `zcons'
    c_local znone_`i' `znone'
end

program __parse_controls
    syntax [varlist(default=none numeric fv)] [, noCONStant NONE ]
    if "`varlist'"=="" local constant
    else               local none
    c_local controls `varlist'
    c_local zcons `constant'
    c_local znone `none'
end

program _parse_vce
    syntax [, vce(str) Robust CLuster(varname) ]
    // old options
    if "`cluster'"!="" {
        if `"`vce'"'!="" {
            di as err "only one of vce() and cluster() allowed"
            exit 198
        }
        local vce cluster `cluster'
    }
    if "`robust'"!="" {
        if `"`vce'"'!="" {
            di as err "only one of vce() and robust allowed"
            exit 198
        }
        local vce robust
    }
    else if `"`vce'"'==substr("robust", 1, strlen(`"`vce'"')) {
        local vce robust
    }
    // check vce type and return
    gettoken vcetype clustvar : vce
    if `"`vcetype'"'==substr("cluster", 1, max(2,strlen(`"`vcetype'"'))) {
        unab clustvar: `clustvar', min(1) name(vce(cluster))
        c_local clustvar `clustvar'
        c_local vceopt vce(cluster `clustvar')
    }
    else if `"`vce'"'=="robust" {
        c_local clustvar
        c_local vceopt
    }
    else {
        di as err "invalid specification in vce()"
        exit 198
    }
end

program _parse_wvar
    syntax anything [if] [pw fw iw aw/]
    // no weights specified => clear local wvar
    if "`weight'"=="" { 
        c_local wvar
        exit
    }
    // exp is a varname => return varname in local wvar
    capt unab wvar: `exp', min(1) max(1)
    if _rc==1 error _rc
    if _rc==0 {
        c_local wvar `wvar'
        exit
    }
    // exp is an expression => store evaluation in variable wvar
    qui gen double `anything' = `exp' `if'
end

version 14
mata:
mata set matastrict on

void _listreg_IF_sl(real scalar aeq)
{
    real scalar    c, touse
    real colvector w, t
    real matrix    X
    real matrix    IFc, Gxz
    
    touse = st_varindex(st_local("touse"))
    if (st_local("wvar")=="") w = 1
    else st_view(w=., ., st_local("wvar"), touse)
    st_view(t=., ., st_local("T"), touse)
    st_view(X=., ., st_local("varlist"), touse)
    c = st_local("constant")==""
    IFc = _listreg_IFc("_1", w, t, X, c, touse, Gxz=.)
    st_store(., tokens(st_local("IFb")), touse,
        _listreg_IFb("", t, X, c, touse, IFc, Gxz))
    if (aeq) st_store(., tokens(st_local("IFc_1")), touse, IFc)
}

void _listreg_IF_dl(real scalar aeq)
{
    real scalar    hasw, c, touse
    real rowvector IFb
    real colvector w, t, r
    real matrix    X
    real matrix    Gxz, IFc
    
    // setup
    IFb = st_varindex(tokens(st_local("IFb")))
    hasw = st_local("wvar")!=""
    if (!hasw) w = 1
    c = st_local("constant")==""
    // ll
    touse = st_varindex(st_local("touse_p"))
    if (hasw) st_view(w=., ., st_local("wvar"), touse)
    st_view(r=., ., st_local("r"), touse)
    st_view(X=., ., st_local("varlist"), touse)
    st_store(., IFb, touse, (X:*r, J(1,c,r)))
    // sl1
    touse = st_varindex(st_local("touse_1"))
    if (hasw) st_view(w=., ., st_local("wvar"), touse)
    st_view(t=., ., st_local("T"), touse)
    st_view(X=., ., st_local("varlist"), touse)
    IFc = _listreg_IFc("_1", w, t, X, c, touse, Gxz=.)
    st_store(., IFb, touse, st_data(., IFb, touse) - IFc * Gxz')
    if (aeq) st_store(., tokens(st_local("IFc_1")), touse, IFc)
    // sl2
    touse = st_varindex(st_local("touse_2"))
    if (hasw) st_view(w=., ., st_local("wvar"), touse)
    t = !st_data(., st_local("T"), touse)
    st_view(X=., ., st_local("varlist"), touse)
    IFc = _listreg_IFc("_2", w, t, X, c, touse, Gxz=.)
    st_store(., IFb, touse, st_data(., IFb, touse) - IFc * Gxz')
    if (aeq) st_store(., tokens(st_local("IFc_2")), touse, IFc)
    // finish
    touse = st_varindex(st_local("touse"))
    st_store(., IFb, touse, st_data(., IFb, touse) *
        st_matrix(st_local("invG"))')
}

void _listreg_IF_avg(real scalar l, real scalar aeq)
{
    string scalar  sfx
    real scalar    c, touse
    real colvector w, t
    real matrix    X
    real matrix    IFb, IFc, Gxz
    
    if (l==2) sfx = "_2"
    else      sfx = "_1"
    touse = st_varindex(st_local("touse"+sfx))
    if (st_local("wvar")=="") w = 1
    else st_view(w=., ., st_local("wvar"), touse)
    if (l==2) t = !st_data(., st_local("T"), touse)
    else      st_view(t=., ., st_local("T"), touse)
    st_view(X=., ., st_local("varlist"), touse)
    c = st_local("constant")==""
    IFc = _listreg_IFc(sfx, w,  t, X, c, touse, Gxz=.)
    IFb = _listreg_IFb(sfx, t, X, c, touse, IFc, Gxz)
    st_store(., tokens(st_local("IFb")), touse,
        st_data(., st_local("IFb"), touse) + IFb/2)
    if (aeq) {
        st_store(., tokens(st_local("IFc"+sfx)), touse, IFc)
        st_store(., tokens(st_local("IFb"+sfx)), touse, IFb)
    }
}

real matrix _listreg_IFb(string scalar sfx, real colvector t, 
    real matrix X, real scalar c, real scalar touse, real matrix IFc,
    real matrix Gxz)
{
    real colvector r
    real matrix    invG
    
    st_view(r=., ., st_local("r"+sfx), touse)
    invG = st_matrix(st_local("invG"+sfx)) // = (X'X)^(-1)
    return(((X:*r, J(1,c,r)) :* t - IFc * Gxz') * invG')
}

real matrix _listreg_IFc(string scalar sfx, real colvector w, real colvector t,
    real matrix X, real scalar c, real scalar touse, real matrix Gxz)
{
    real scalar    cz
    real colvector rz
    real matrix    Z
    real matrix    invGz
    
    st_view(Z=., ., st_local("zvars"+sfx), touse)
    cz = st_local("zcons"+sfx)==""
    st_view(rz=., ., st_local("rz"+sfx), touse)
    invGz = st_matrix(st_local("invGz"+sfx))
    Gxz   = cross(X,c, w:*t, Z,cz)
    return(((Z:*rz, J(1,cz,rz)) :* !t) * invGz')
}

end

exit
