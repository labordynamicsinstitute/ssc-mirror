*! version 1.0.1  14mar2024  Ben Jann

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
    if `"`e(controls_1)'`e(controls_2)'"'!="" {
        local dl 1
        local space "  "
    }
    else {
        local dl 0
        local space ""
    }
    if `"`e(dlmethod)'"'!="" {
        di as txt "Double-list method:  `space'" as res e(dlmethod)
        di as txt "Outcome variables:   `space'" as res e(depvar)
    }
    di as txt "Long-list indicator: `space'" as res e(tvar) as txt " (N = " /*
        */ as res el(e(_N),1,2) as txt " in group 1, N = "/*
        */ as res el(e(_N),1,1) as txt " in group 0)"
    if !`dl' {
        if `"`e(indepvars)'`e(controls)'"'=="" exit
    }
    forv i = 1/2 {
        if `dl' {
            local sfx _`i'
            local lbl "Short-list `i' equation: "
        }
        else {
            local sfx
            local lbl "Short-list equation: "
        }
        if `"`e(controls`sfx')'"'=="" {
            local msg `""(empty)""'
        }
        else if `"`e(controls`sfx')'"'==`"`e(indepvars)'"' {
            local msg `""(same as main equation)""'
        }
        else if strlen(`"`e(controls`sfx')'"')>57 {
            local msg `""{bf:{stata display e(controls`sfx'):e(controls`sfx')}}""'
        }
        else {
            local msg as res e(controls`sfx')
        }
        di as txt "`lbl'" `msg'
        if "`sfx'"=="" continue, break
    }
end

program Estimate, eclass
    version 14
    
    // syntax
    gettoken ovar1 0 : 0, parse(" ,")
    gettoken ovar2 0 : 0, parse(" =,")
    gettoken eq      : 0, parse(" =,")
    if `"`eq'"'=="=" {
        gettoken eq 0 : 0, parse(" =,")
        local ovar `ovar1' `ovar2'
        gettoken tvar 0 : 0, parse(" ,")
    }
    else if `"`ovar2'"'=="=" {
        local ovar `ovar1'
        gettoken tvar 0 : 0, parse(" ,")
    }
    else {
        local ovar `ovar1'
        local tvar `ovar2'
    }
    capt n _parse_ovar `ovar'
    if _rc==1 exit _rc
    if _rc {
        di as err "invalid {it:ovar}"
        exit _rc
    }
    local dl = `: list sizeof ovar'==2
    capt n _parse_tvar `tvar'
    if _rc==1 exit _rc
    if _rc {
        di as err "invalid {it:tvar}"
        exit _rc
    }
    if `dl' local opts *
    else    local opts
    syntax [varlist(default=none numeric fv)] [if] [in] [pw fw iw] [,/*
        */ noCONStant Controls(str) AVErage NOIsily/*
        */ NOSE vce(passthru) Robust CLuster(passthru) NODF/*
        */ IFGENerate(str) replace/*
        */ saveifuninmata/* technical option for svy; do not use manually
        */ Level(cilevel)/* (not used)
        */ `opts' ]
    if "`constant'"!="" {
        if "`varlist'"=="" {
            di as err "{bf:noconstant} not allowed if {it:indepvars} is empty"
            exit 198
        }
    }
    _parse_controls `controls' // returns controls and zcons
    if `dl' {
        local dl = `dl' + ("`average'"!="")
        local controls_0 `controls'
        local zcons_0 `zcons'
        local znone_0 `znone'
        _parse_controls_2, `options'
        if "`controls_1'`znone_1'"=="" {
            local controls_1 `controls'
            local zcons_1 `zcons'
            local znone_1 `znone'
        }
        else local controls: list controls | controls_1
        local zcons
        local znone
    }
    else local average
    if "`noisily'"=="" local qui quietly
    else               local qui

    // process vce
    _parse_vce, `vce' `robust' `cluster' // returns vceopt, clustvar

    // mark sample and weights
    marksample touse
    markout `touse' `ovar' `tvar' `controls'
    if "`clustvar'"!="" {
        markout `touse' `clustvar', strok
    }
    tempvar wvar
    _parse_wvar `wvar' [`weight'`exp'] if `touse'
    if "`wvar'"!="" {
        local wgt  [`weight'=`wvar']
        local iwgt [iw=`wvar']
    }
    _nobs `touse' `wgt' if `touse'
    local N = r(N)
    
    // generate long list indicator
    tempvar T
    qui gen byte `T' = (`tvar')==1 if `touse'
    tempname _N
    mat `_N' = J(1,2,.)
    mat coln `_N' = 0 1
    capt _nobs `touse' `wgt' if `touse' & `T'==1
    if _rc==2000 {
        di as err "no observations in group 1"
        exit 2000
    }
    else if _rc error _rc
    mat `_N'[1,2] = r(N)
    capt _nobs `touse' `wgt' if `touse' & `T'==0
    if _rc==2000 {
        di as err "no observations in group 0"
        exit 2000
    }
    else if _rc error _rc
    mat `_N'[1,1] = r(N)
    
    // expand factor variables and fill in controls if needed
    fvexpand `varlist' if `touse'
    local xvars `r(varlist)'
    forv i=0/1 {
        if `dl' local sfx _`i'
        else    local sfx
        if "`controls`sfx''`znone`sfx''"=="" {
            local controls`sfx' `varlist'
            local zvars`sfx' `xvars'
            local zcons`sfx' `constant'
        }
        else if "`znone`sfx''"=="" {
            fvexpand `controls`sfx'' if `touse'
            local zvars`sfx' `r(varlist)'
        }
        else {
            local zvars`sfx'
            local zcons`sfx'
        }
        if "`sfx'"=="" continue, break // single list
    }
    
    // parse ifgenerate()
    if `"`ifgenerate'"'!="" {
        if strpos(`"`ifgenerate'"',"*") {
            gettoken ifstub rest : ifgenerate, parse("* ")
            if `"`rest'"'!="*" {
                di as err "ifgenerate() invalid; " /*
                    */ "must specify {it:stub}{bf:*} or {it:namelist}"
                exit 198
            }
            confirm name `ifstub'
            local k: list sizeof xvars
            if "`constant'"=="" local k = `k' + 1
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
    local IF = "`nose'"=="" | "`ifgenerate'`saveifuninmata'"!=""
    
    // short-list model
    if `dl' {
        local i 0
        foreach v of local ovar {
            `qui' di _n as txt "- short list `=`i'+1'"
            tempvar rz_`i' invGz_`i'
            `qui' regress `v' `zvars_`i'' `iwgt' if `T'==`i' & `touse',/*
                */ `zcons_`i''
            if `IF' mat `invGz_`i'' = e(V) / e(rmse)^2
            qui predict double `rz_`i'' if `touse', resid
            local ++i
        }
        if `dl'<2 {
            tempvar rz
            qui gen double `rz' = cond(`T'==1, `rz_0', `rz_1') if `touse'
        }
    }
    else {
        `qui' di _n as txt "- short list"
        tempvar rz invGz
        `qui' regress `ovar' `zvars' `iwgt' if `T'==0 & `touse', `zcons'
        if `IF' mat `invGz' = e(V) / e(rmse)^2
        predict double `rz', resid
    }
    
    // long-list model
    if `dl'==2 {
        local i 0
        foreach v of local ovar {
            `qui' di _n as txt "- residualized long list `=`i'+1'"
            tempname r_`i' b_`i' invG_`i'
            `qui' regress `rz_`i'' `xvars' `iwgt'/*
                */ if `T'!=`i' & `touse', `constant'
            mat `b_`i'' = e(b)
            if `IF' {
                mat `invG_`i'' = e(V) / e(rmse)^2
                qui predict double `r_`i'' if `touse', resid
            }
            local ++i
        }
        tempname b
        mat `b' = (`b_0' + `b_1') / 2
    }
    else {
        `qui' di _n as txt "- residualized long list"
        tempname r b invG
        if `dl' local iff `touse'
        else    local iff `T'==1 & `touse'
        `qui' regress `rz' `xvars' `iwgt' if `iff', `constant'
        mat `b' = e(b)
        if `IF' {
            mat `invG' = e(V) / e(rmse)^2
            qui predict double `r' if `touse', resid
        }
    }
    
    // variance estimation
    if `IF' {
        // compute IFs
        local k = colsof(`b')
        forv i = 1/`k' {
            tempname tmp
            qui gen double `tmp' = .
            local IFs `IFs' `tmp'
        }
        mata: listreg_IF(`dl', "`touse'")
        
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
            mat coln `V' = `: coln `b''
            mat rown `V' = `: coln `b''
            if "`nodf'"!="" { // ignore df_r, like GMM
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
        if "`controls_0'"=="`controls_1'" {
            eret local controls "`controls_0'"
        }
        else {
            eret local controls_1 "`controls_0'"
            eret local controls_2 "`controls_1'"
        }
    }
    else {
        eret local controls "`controls'"
    }
    eret matrix _N = `_N'
    if "`nose'"=="" {
        eret scalar rank = `rank'
        if "`nodf'"=="" {
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
            if "`nodf'"!="" eret scalar chi2 = r(chi2)
            else            eret scalar F    = r(F)
            eret scalar df_m = r(df)
            eret scalar p    = r(p)
        }
    }
    
    // generate
    if "`ifgenerate'"!="" {
        local coln: coln e(b)
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
    syntax [varlist(default=none numeric fv)] [, noCONStant NONE ]
    if "`varlist'"=="" local constant
    else               local none
    c_local controls `varlist'
    c_local zcons `constant'
    c_local znone `none'
end

program _parse_controls_2
    syntax [, Controls(str) ]
    _parse_controls `controls'
    c_local controls_1 `controls'
    c_local zcons_1 `zcons'
    c_local znone_1 `znone'
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

void listreg_IF(real scalar dl, string scalar touse)
{
    real scalar    c
    real colvector w, t
    real matrix    IF, X
    
    st_view(IF=., ., st_local("IFs"), touse)
    if (st_local("wvar")=="") w = 1
    else                      st_view(w=., ., st_local("wvar"), touse)
    st_view(t=., ., st_local("T"), touse)
    st_view(X=., ., st_local("varlist"), touse)
    c = st_local("constant")==""
    if (dl<2) IF[.,.] =  listreg_IFx("",  dl, w,  t, X, c, touse)
    else      IF[.,.] = (listreg_IFx("_0", 0, w,  t, X, c, touse) +
                         listreg_IFx("_1", 0, w, !t, X, c, touse)) / 2
}

real matrix listreg_IFx(string scalar sfx, real scalar dl, real colvector w,
    real colvector t, real matrix X, real scalar c, string scalar touse)
{
    real colvector r
    real matrix    invG
    
    st_view(r=., ., st_local("r"+sfx), touse)
    invG = st_matrix(st_local("invG"+sfx)) // = (X'X)^(-1)
    if (dl) return(((X:*r, J(1,c,r))
        - listreg_IFz("_0", w,  t, X, c, touse)
        - listreg_IFz("_1", w, !t, X, c, touse)) * invG')
    return(((X:*r, J(1,c,r)) :* t
        - listreg_IFz(sfx, w, t, X, c, touse)) * invG')
}


real matrix listreg_IFz(string scalar sfx, real colvector w, real colvector t,
    real matrix X, real scalar c, string scalar touse)
{
    real scalar    cz
    real colvector rz
    real matrix    Z
    real matrix    invGz, Gxz
    
    st_view(Z=., ., st_local("zvars"+sfx), touse)
    cz = st_local("zcons"+sfx)==""
    st_view(rz=., ., st_local("rz"+sfx), touse)
    invGz = st_matrix(st_local("invGz"+sfx))
    Gxz   = cross(X,c, w:*t, Z,cz)
    return(((Z:*rz, J(1,cz,rz)) :* !t) * invGz' * Gxz')
}

end

exit
