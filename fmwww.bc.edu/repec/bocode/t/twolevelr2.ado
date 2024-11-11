*! version 1.0.2  04oct2024  Ben Jann

program twolevelr2, rclass sortpreserve
    version 14.2
    
    // syntax
    syntax varlist(fv) [if] [in], Ivar(varname numeric)/*
        */ [ PWeights(varlist numeric max=2) FWeights(varlist numeric max=2)/*
        */ IWeights(passthru)/*
        */ JOINTly v2tol(real 1e-15) NOIsily * ]
    if "`noisily'"!="" {
        local noi
        local qui qui
    }
    else {
        local noi qui
        local qui
    }
    if `"`iweights'"'!="" {
        di as err "{bf:iweights()} not allowed"
        exit 198
    }
    if `:list sizeof pweights' {
        if `:list sizeof fweights' {
            di as err "only one of pweights() and fweights() allowed"
            exit 198
        }
        local wtype pw
        gettoken w1 w2 : pweights
        gettoken w2    : w2
        local options pweights(`pweights') `options'
    }
    if `:list sizeof fweights' {
        local wtype fw
        gettoken w1 w2 : fweights
        gettoken w2    : w2
        local options fweights(`fweights') `options'
    }
    
    // backup current e()
    tempname ecurrent
    _estimates hold `ecurrent', nullok restore
    
    // mark estimation sample
    marksample touse
    markout `touse' `ivar' `w1' `w2'
    if      "`w2'"!="" _nobs `touse' [`wtype'=`w1'*`w2']
    else if "`w1'"!="" _nobs `touse' [`wtype'=`w1']
    else               _nobs `touse'
    local N = r(N)
    
    // prepare groups
    sort `touse' `ivar'
    tempvar tag
    qui by `touse' `ivar': gen `tag' = _n==1 & `touse'
    if  "`w2'"!="" _nobs `tag' [`wtype'=`w2']
    else           _nobs `tag'
    local N_g = r(N)
    
    // parse varlist
    gettoken depvar vars : varlist
    _fv_check_depvar `depvar'
    fvexpand `vars' if `touse'
    local vars `r(varlist)'
    fvrevar `vars' if `touse'
    local VARS `r(varlist)'
    
    // check depvar
    local v1 `depvar'
    capt by `touse' `ivar': assert (`v1'==`v1'[1]) if `touse'
    if _rc==1 exit 1
    if !_rc {
        di as err "dependent variable has no level 1 variance"
        exit 499
    }
    _l2zero `v2tol' l2zero1 `touse' `tag' `ivar' `v1' `w1' `w2'
    
    // determine predictor types
    local xvars
    local zvars
    local ZVARS
    local ovars
    local kx 1 // (-> number of level 1 variables, including depvar)
    foreach X of local VARS {
        gettoken x vars : vars
        capt by `touse' `ivar': assert (`X'==`X'[1]) if `touse'
        if _rc==1 exit 1
        if _rc { // has variance at level 1
            local ++kx
            local v`kx' `X'
            local xvars `xvars' `x'
            _l2zero `v2tol' l2zero`kx' `touse' `tag' `ivar' `X' `w1' `w2'
        }
        else { // no variance at level 1
            capt by `touse': assert (`X'==`X'[1]) if `tag'
            if _rc==1 exit 1
            if _rc { // has variance at level 2
                local zvars `zvars' `x'
                local ZVARS `ZVARS' `X'
            }
            else { // no variance at level 2
                local ovars `ovars' `x'
            }
        }
    }
    local kz: list sizeof zvars
    local ko: list sizeof ovars
    di as txt "(level 1 predictors: " _c
    if `kx'>1 di "`xvars')"
    else      di "<none>)"
    di as txt "(level 2 predictors: " _c
    if `kz'   di "`zvars')"
    else      di "<none>)"
    di as txt "(omitted predictors: " _c
    if `ko'   di "`ovars')"
    else      di "<none>)"

    // estimate variances and covariances
    tempname Vu Ve
    mat `Vu' = J(`kx', `kx', 0)
    mat `Ve' = `Vu'
    if `kz' {
        tempname bz
        matrix `bz' = J(1, `kz', 0)
    }
    if "`jointly'"!="" { // using multivariate model
        `qui' di as txt "(estimating multivariate model ..." _c
        local eqs
        local latent
        forv i = 1/`kx' {
            if `l2zero`i'' {
                local eqs `eqs' (`v`i'' <- )
            }
            else {
                tempname M`i'
                local latent `latent' `M`i''
                local eqs `eqs' (`v`i'' <- `ZVARS' `M`i''[`ivar'])
            }
        }
        if "`latent'"!="" local latent latent(`latent')
        else              local latent nocapslatent
        `noi' gsem `eqs' if `touse',/*
            */ `latent' covstructure(e._En, unstructured) `options'
        forv i = 1/`kx' {
            if !`l2zero`i'' {
                matrix `Vu'[`i',`i'] = _b[/var(`M`i''[`ivar'])]
            }
            matrix `Ve'[`i',`i'] = _b[/var(e.`v`i'')]
            forv j = `=`i'+1'/`kx' {
                if !`l2zero`i'' & !`l2zero`j'' {
                    matrix `Vu'[`i',`j'] = /*
                        */ _b[/cov(`M`i''[`ivar'],`M`j''[`ivar'])]
                    matrix `Vu'[`j',`i'] = `Vu'[`i',`j']
                }
                matrix `Ve'[`i',`j'] = _b[/cov(e.`v`i'',e.`v`j'')]
                matrix `Ve'[`j',`i'] = `Ve'[`i',`j']
            }
        }
        // copy depvar equation
        if `kz' {
            if !`l2zero1' {
                matrix `bz' = e(b)
                matrix `bz' = `bz'[1,1..`kz']
            }
        }
        `qui' di as txt " done)"
    }
    else { // using pairwise models
        local msg = comb(`kx',2)
        if `msg'==1 local msg "1 pairwise model"
        else        local msg "`msg' pairwise models"
        `qui' di as txt "(estimating `msg' " _c
        tempname Mi Mj cnt
        matrix `cnt' = J(1, `kx', 0) // counter for mean updating
        if `kz' tempname bztmp
        forv i = 1/`kx' {
            forv j = `=`i'+1'/`kx' {
                matrix `cnt'[1,`i'] = `cnt'[1,`i'] + 1
                matrix `cnt'[1,`j'] = `cnt'[1,`j'] + 1
                if `l2zero`i'' {
                    if `l2zero`j'' {
                        `noi' gsem (`v`i'' <- )/*
                                */ (`v`j'' <- )/*
                            */ if `touse',/*
                            */ nocapslatent cov(e.`v`i''*e.`v`j'') `options'
                    }
                    else {
                        `noi' gsem (`v`i'' <- )/*
                                */ (`v`j'' <- `ZVARS' `Mj'[`ivar'])/*
                            */ if `touse',/*
                            */ latent(`Mj') cov(e.`v`i''*e.`v`j'') `options'
                        _addtoV `cnt' `Vu' `j' _b[/var(`Mj'[`ivar'])]
                    }
                }
                else {
                    if `l2zero`j'' {
                        `noi' gsem (`v`i'' <- `ZVARS' `Mi'[`ivar'])/*
                                */ (`v`j'' <- )/*
                            */ if `touse',/*
                            */ latent(`Mi') cov(e.`v`i''*e.`v`j'') `options'
                        _addtoV `cnt' `Vu' `i' _b[/var(`Mi'[`ivar'])]
                    }
                    else {
                        `noi' gsem (`v`i'' <- `ZVARS' `Mi'[`ivar'])/*
                                */ (`v`j'' <- `ZVARS' `Mj'[`ivar'])/*
                            */ if `touse',/*
                            */ latent(`Mi' `Mj') cov(e.`v`i''*e.`v`j'')/*
                            */ `options'
                        _addtoV `cnt' `Vu' `i' _b[/var(`Mi'[`ivar'])]
                        _addtoV `cnt' `Vu' `j' _b[/var(`Mj'[`ivar'])]
                        matrix `Vu'[`j',`i'] = /*
                            */ _b[/cov(`Mi'[`ivar'],`Mj'[`ivar'])]
                    }
                }
                _addtoV `cnt' `Ve' `i' _b[/var(e.`v`i'')]
                _addtoV `cnt' `Ve' `j' _b[/var(e.`v`j'')]
                matrix `Ve'[`j',`i'] = _b[/cov(e.`v`i'',e.`v`j'')]
                // copy depvar equation
                if `i'==1 {
                    if `kz' {
                        if !`l2zero1' {
                            matrix `bztmp' = e(b)
                            matrix `bztmp' = `bztmp'[1,1..`kz']
                            matrix `bz' = `bz' + (`bztmp' - `bz') / `cnt'[1,`i']
                        }
                    }
                }
                `qui' di as txt "." _c
            }
        }
        mata:  st_replacematrix("`Vu'", makesymmetric(st_matrix("`Vu'")))
        mata:  st_replacematrix("`Ve'", makesymmetric(st_matrix("`Ve'")))
        `qui' di as txt " done)"
    }

    // get variances of level2 predictors
    tempname bVz
    if `kz' {
        tempname Vz
        if "`w2'"!="" qui corr `ZVARS' if `tag' [aw=`w2'], cov
        else          qui corr `ZVARS' if `tag', cov
        matrix `Vz' = r(C) * ((r(N)-1)/r(N))
        matrix `bVz' = `bz' * `Vz' * `bz''
    }
    else matrix `bVz' = 0
    
    // compute r2
    tempname bu be bVu bVe r2u r2e r2
    if `kx'>1 {
        matrix `bu'  = (invsym(`Vu'[2...,2...]) * `Vu'[2...,1])'
        matrix `bVu' = `bu' * `Vu'[2...,2...] * `bu''
        matrix `be'  = (invsym(`Ve'[2...,2...]) * `Ve'[2...,1])'
        matrix `bVe' = `be' * `Ve'[2...,2...] * `be''
    }
    else {
        matrix `bVu' = 0
        matrix `bVe' = 0
    }
    if `l2zero1' {
        scalar `r2'  = `bVe'[1,1] / `Ve'[1,1]
        scalar `r2u' = 0
        scalar `r2e' = `bVe'[1,1] / `Ve'[1,1]
    }
    else {
        scalar `r2'  = (`bVz'[1,1] + `bVu'[1,1] + `bVe'[1,1]) / /*
                    */ (`bVz'[1,1] + `Vu'[1,1] + `Ve'[1,1])
        scalar `r2u' = (`bVz'[1,1] +`bVu'[1,1]) / (`bVz'[1,1] + `Vu'[1,1])
        scalar `r2e' = `bVe'[1,1] / `Ve'[1,1]
    }

    // returns
    return local cmd       "twolevelr2"
    return local cmdline   `"`0'"'
    return local ivar      "`ivar'"
    return local depvar    "`depvar'"
    return local xvars     "`xvars'"
    return local zvars     "`zvars'"
    return local ovars     "`ovars'"
    return local jointly   "`jointly'"
    if      "`wtype'"=="pw" return local pweights "`pweights'"
    else if "`wtype'"=="fw" return local fweights "`fweights'"
    return scalar N    = `N'
    return scalar N_g  = `N_g'
    return scalar k_x  = `kx'-1
    return scalar k_z  = `kz'
    return scalar k_o  = `ko'
    return scalar r2_w = `r2e'
    return scalar r2_b = `r2u'
    return scalar r2   = `r2'
    mat coln `bu' = `xvars'
    return matrix b_u = `bu'
    mat coln `Vu' = `depvar' `xvars'
    mat rown `Vu' = `depvar' `xvars'
    return matrix V_u   = `Vu'
    mat coln `be' = `xvars'
    return matrix b_e = `be'
    mat coln `Ve' = `depvar' `xvars'
    mat rown `Ve' = `depvar' `xvars'
    return matrix V_e   = `Ve'
    if `kz' {
        mat coln `bz' = `zvars'
        return matrix b_z = `bz'
        mat coln `Vz' = `zvars'
        mat rown `Vz' = `zvars'
        return matrix V_z  = `Vz'
    }
    
    // display
    tempname R
    mat `R' = `r2e' \ `r2u' \ `r2'
    mat coln `R' = "`depvar'"
    mat rown `R' = "Within (level 1)" "Between (level 2)" "Overall"
    di ""
    di _col(5) as txt "Number of obs    = " as res %9.0gc `N'
    di _col(5) as txt "Number of groups = " as res %9.0gc `N_g'
    matlist `R', border(rows) twidth(20) rowtitle("R-squared")
end

program _l2zero // check whether there is variance in group means
    args tol nm touse tag ivar v w1 w2
    tempname M
    _grpmeans `M' `v' `touse' `ivar' `w1'
    if "`w2'"!="" qui su `M' if `tag' [aw=`w2']
    else          qui su `M' if `tag'
    c_local `nm' = (r(Var) * ((r(N)-1)/r(N))) < `tol'
end

program _grpmeans
    args M X touse id w1
    if "`w1'"!="" {
        tempname W
        qui by `touse' `id': gen double `M' = sum(`X'*`w1') if `touse'
        qui by `touse' `id': gen double `W' = sum(`w1') if `touse'
        qui by `touse' `id': replace    `M' = `M'[_N] / `W'[_N] if `touse'
    }
    else {
        qui by `touse' `id': gen double `M' = sum(`X') if `touse'
        qui by `touse' `id': replace    `M' = `M'[_N] / _N if `touse'
    }
end

program _addtoV
    gettoken N 0 : 0
    gettoken V 0 : 0
    gettoken i 0 : 0
    matrix `V'[`i',`i'] = `V'[`i',`i'] + (`0' - `V'[`i',`i']) / `N'[1,`i']
end

