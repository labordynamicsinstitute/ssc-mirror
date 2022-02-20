*! version 2.0.8  18sep2021  Ben Jann

capt findfile lmoremata.mlib
if _rc {
    di as error "the {bf:moremata} package is required; type {stata ssc install moremata, replace}"
    error 499
}

program robreg, eclass properties(svyr svyb svyj)
    version 11
    if replay() { // redisplay output
        syntax [, all noHEADer NOTABle * ]
        _get_diopts diopts options, `options'
        _get_eformopts, eformopts(`options') allowed(__all__)
        Display, `all' `header' `notable' `s(eform)' `diopts'
        exit
    }
    gettoken subcmd : 0, parse(", ")
    if `"`subcmd'"'=="predict" {
        gettoken subcmd 0 : 0, parse(", ")
        Predict `0'
        exit
    }
    if `"`subcmd'"'==substr("hausman", 1, max(4,strlen(`"`subcmd'"'))) {
        gettoken subcmd 0 : 0, parse(", ")
        Hausman `0'
        exit
    }
    local cmdlist "ls q m s mm lms lts lqs"
    if !`:list subcmd in cmdlist' {
        di as err `"invalid subcommand: `subcmd'"'
        exit 198
    }
    if "`subcmd'"=="mm" {
        _parse comma lhs rhs : 0
        if `"`lhs'"'=="mm" {
            ReEstimate_mm `rhs' // returns diopts
            ereturn local cmdline `"robreg `0'"'
            Display, `diopts'
            exit
        }
    }
    local version : di "version " string(_caller()) ":"
    Check_vce `0' // returns hasvce, 00
    if "`hasvce'"!="" { // bootstrap/jackknife
        `version' _vce_parserun robreg, noeqlist: `00'
        ereturn local cmdline `"robreg `0'"'
        exit
    }
    Estimate `0' // returns diopts
    ereturn local cmdline `"robreg `0'"'
    Display, `diopts'
    if `"`e(ugenerate)'"'!="" {
        di as txt `"(fixed effects stored in variable {bf:`e(ugenerate)'})"'
    }
end

program Check_vce
    _parse comma lhs 0 : 0
    syntax [, vce(str) NOSE UGENerate(passthru) * ]
    if `"`vce'"'=="" exit
    gettoken vcetype : vce, parse(" ,")
    if `"`vcetype'"'!= substr("bootstrap",1,max(4,strlen(`"`vcetype'"'))) ///
     & `"`vcetype'"'!= substr("jackknife",1,max(4,strlen(`"`vcetype'"'))) {
         exit
    }
    if `"`ugenerate'"'!="" {
        di as err "{bf:ugenerate()} not allowed with {bf:vce(`vcetype')}"
        exit 198
    }
    c_local hasvce 1
    c_local 00 `lhs', nose vce(`vce') `options'
end

program Display
    syntax [, all noHEADer NOTABle * ]
    if !inlist(`"`e(cmd)'"',"robreg","xtrobreg") {
        di as err "last robreg estimates not found"
        exit 301
    }
    if "`all'"!="" {
        if e(k_eq)==1 local all ""
    }
    else {
        if e(k_eq)!=1 local first first
    }
    local subcmd `"`e(subcmd)'"'
    if "`header'"=="" {
        local nofgrps "Number of groups"
        if c(stata_version)<14 {
            if `"`e(prefix)'"'!="" {
                local c1 _col(49)
                local c2 _col(68)
                local c3 _col(64)
                local w2 9
            }
            else {
                local c1 _col(51)
                local c2 _col(67)
                local c3 _col(63)
                local w2 10
                local nofgrps "No. of groups"
            }
        }
        else {
            local c1 _col(49)
            local c2 _col(67)
            local c3 _col(63)
            local w2 10
            local head2opts head2left(17) head2right(`w2')
            if      c(stata_version)<17            local head2opts
            else if d(`c(born_date)')<d(13jul2021) local head2opts
        }
        capt confirm matrix e(V)
        if _rc==1 exit _rc
        else if _rc local nomodeltest nomodeltest
        else        local nomodeltest
        _coef_table_header, `nomodeltest' `head2opts'
        if "`subcmd'"'=="q" {
            di as txt `c1' `"Sum of abs.dev."' `c2' "= " as res %`w2'.0g e(sum_adev)
        }
        else if "`subcmd'"'=="m" {
            local obf = proper(`"`e(obf)'"')
            di as txt `c1' `"`obf' k"'       `c2' "= " as res %`w2'.0g e(k)
        }
        else if "`subcmd'"'=="s" {
            di as txt `c1' "Breakdown point" `c2' "= " as res %`w2'.0g e(bp)
            di as txt `c1' "Biweight k"      `c2' "= " as res %`w2'.0g e(k)
        }
        else if "`subcmd'"'=="mm" {
            di as txt `c1' "Breakdown point" `c2' "= " as res %`w2'.0g e(bp)
            di as txt `c1' "M-estimate: k "  `c2' "= " as res %`w2'.0g e(k)
            di as txt `c1' "S-estimate: k"   `c2' "= " as res %`w2'.0g e(kS)
        }
        else if inlist(`"`subcmd'"',"lms","lqs","lts") {
            if `"`subcmd'"'!="lms" ///
            di as txt `c1' "Breakdown point" `c2' "= " as res %`w2'.0g e(bp)
        }
        if "`all'"=="" di as txt `c1' "Scale" `c2' "= " as res %`w2'.0g e(scale)
        if e(N_g)<. { // ivar()/avar()/xtrobreg
            di ""
            di as txt "Group variable: " _c
            di as res abbrev(`"`e(ivar)'`e(absorb)'"',12) _c 
            di as txt `c1' "`nofgrps'" `c2' "= " as res %`w2'.0g e(N_g)
            if `"`e(tvar)'"'!="" {
                di as txt "Time variable:  " _c
                di as res abbrev(`"`e(tvar)'"',12) _c 
            }
            di as txt `c1' "Group size:" _c
            di as txt `c3' "min = " as res %`w2'.0g e(g_min)
            di as txt `c3' "avg = " as res %`w2'.0g e(g_avg)
            if `"`e(corr)'"'!="" {
                di as txt "corr(u_i, Xb) = " as res %7.4f e(corr) _c
            }
            di as txt `c3' "max = " as res %`w2'.0g e(g_max)
        }
        di ""
    }
    if "`notable'"=="" {
        eret di, `first' `options'
        if `"`e(hausman_chi2)'`e(hausman_F)'"'!="" {
            if      "`subcmd'"=="s"  di as txt "Hausman test of S against LS:" _c
            else if "`subcmd'"=="mm" di as txt "Hausman test of MM against S:" _c
            else exit // cannot be reached
            if `"`e(hausman_F)'"'!="" {
            di as txt "{col 34}F({res:`e(df_m)'}, {res:`e(df_r)'}) =" /*
                */as res %10.0g e(hausman_F) _c
            di as txt "{col 62}Prob > F = "as res %6.4f e(hausman_p)
            }
            else {
                di as txt "{col 34}chi2({res:`e(df_m)'}) =" /*
                    */as res %10.0g e(hausman_chi2) _c
                di as txt "{col 59}Prob > chi2 = " as res %6.4f e(hausman_p)
            }
        }
    }
end

program Predict
    if `"`e(cmd)'"'!="robreg" {
        di as err "last robreg results not found"
        exit 301
    }
    local subcmd `"`e(subcmd)'"'
    if !inlist(`"`subcmd'"',"ls","q","m","s","mm","lms","lts","lqs") {
        di as err "last robreg results not found"
        exit 301
    }
    
    // syntax
    local opts xb Residuals RStandard /*
        */ OUTlier OUTlier2(numlist >=0 <=100 max=1) /*
        */ INlier  INlier2(numlist >=0 <=100 max=1)
    if !inlist("`subcmd'","lms","lts","lqs") {
        if inlist("`subcmd'","m","s","mm") {
            local opts `opts' Weights
        }
        if inlist("`subcmd'","ls","m","s","mm") {
            local opts `opts' xbu u ue
        }
        local opts `opts' SCores IFs RIFs
    }
    else {
        local opts `opts' SUBset
    }
    syntax [anything] [if] [in], [ `opts' ]
    if "`outlier2'"!=""     local outlier  outlier
    else if "`outlier'"!="" local outlier2 2.5
    if "`inlier2'"!=""      local inlier   inlier
    else if "`inlier'"!=""  local inlier2  97.5
    local opt `xb' `xbu' `u' `ue' `residuals' `rstandard' `weights' /*
        */ `outlier' `inlier' `subset' `scores' `ifs' `rifs'
    if "`opt'"=="" local opt xb
    if `: list sizeof opt'>1 {
        di as err "`opt': only one allowed"
        exit 198
    }
    
    // obtain fixed effects if ivar() or absorb()
    local ivar = (`"`e(ivar)'`e(absorb)'"'!="")
    if `ivar' & !inlist("`opt'","xb","ue") {
        tempname U esample
        qui gen byte `esample' = e(sample)==1
        qui gen double `U' = .
        capt confirm matrix e(u)
        if _rc==0 mata: rr_fillin_u()
        else if `"`e(ugenerate)'"'!="" {
            capt confirm variable `e(ugenerate)', exact
            if _rc {
                di as err `"variable {bf:`e(ugenerate)'} (fixed "' ///
                    "effects) not found; cannot compute {bf:`opt'}"
                exit 111
            }
            capt mata: assert(st_matrix("e(uminmax)") == /*
                */ minmax(st_data(.,"`e(ugenerate)'"',"`esample'")))
            if _rc {
                di as err `"variable {bf:`e(ugenerate)'} does not"' ///
                    " contain valid fixed effects; cannot compute {bf:`opt'}"
                exit 498
            }
            qui replace `U' = `e(ugenerate)' if `esample'
        }
        else if "`subcmd'"=="ls" {
            tempname XB
            predict_ls_U `XB' `U' `esample'
        }
        else {
            di as err "no information on fixed effects available; " ///
               "cannot compute {bf:`opt'}"
            exit 498
        }
    }
    
    // mark sample
    local userif = (`"`if'`in'"'!="")
    marksample touse
    
    // single-variable predictions
    if !inlist("`opt'","scores","ifs","rifs") {
        syntax newvarname [if] [in] [, * ]
        // linear prediction
        if "`opt'"=="xb" {
            _predict `typlist' `varlist' if `touse', xb nolabel
            lab var `varlist' "Fitted values"
            exit
        }
        // fixed effect
        if "`u'"!="" {
            if `ivar'==0 {
                di as err "{bf:u} only allowed after {bf:ivar()}" ///
                    " or {bf:absorb()} has been specified"
                exit 198
            }
            gen `typlist' `varlist' = `U' if `touse'
            lab var `varlist' "Fixed effect"
            exit
        }
        // fixed effect plus linear prediction
        if "`XB'"!="" local z `XB'
        else {
            tempname z
            qui _predict double `z' if `touse', xb nolabel
        }
        if "`subcmd'"=="ls" & "`opt'"=="weights" { // do weights for ls here
            gen `typlist' `varlist' = `z'^0 if `touse' // = 1
            lab var `varlist' "RLS weights"
            exit
        }
        if "`xbu'"!="" {
            if `ivar'==0 {
                di as err "{bf:xbu} only allowed after {bf:ivar()}" ///
                    " or {bf:absorb()} has been specified"
                exit 198
            }
            gen `typlist' `varlist' = `z' + `U' if `touse'
            lab var `varlist' "Linear prediction plus fixed effect"
            exit
        }
        // fixed effect plus residual
        if "`ue'"!="" {
            if `ivar'==0 {
                di as err "{bf:ue} only allowed after {bf:ivar()}" ///
                    " or {bf:absorb()} has been specified"
                exit 198
            }
            gen `typlist' `varlist' = `e(depvar)' - `z' if `touse'
            lab var `varlist' "Fixed effect plus residual"
            exit
        }
        if `ivar' {
            qui replace `z' = `z' + `U' if `touse' // xb + u
        }
        // residuals
        if "`opt'"=="residuals" {
            gen `typlist' `varlist' = `e(depvar)' - `z' if `touse'
            lab var `varlist' "Residuals"
            exit
        }
        // standardized residuals
        tempname c
        scalar `c' = cond(e(scale)==0, 0, 1 / e(scale))
        if "`opt'"=="rstandard" {
            gen `typlist' `varlist' = (`e(depvar)' - `z') * `c' if `touse'
            lab var `varlist' "Standardized residuals"
            exit
        }
        // outlier / inlier
        if inlist("`opt'","outlier","inlier") {
            if `"`typlist'"'=="" local typlist byte // use byte as default
            if ``opt'2'==0   & "`opt'"=="outlier" local exp "*0" // all zero
            if ``opt'2'==100 & "`opt'"=="inlier"  local exp "^0" // all one
            else {
                qui replace `z' = abs((`e(depvar)'-`z') * `c') if `touse'
                tempname k
                if "`opt'"=="outlier" {
                    scalar `k' = invnormal(1 - ``opt'2'/200)
                    local exp ">`k'"
                }
                else {
                    scalar `k' = invnormal(.5 + ``opt'2'/200)
                    local exp "<=`k'"
                }
            }
            gen `typlist' `varlist' = `z'`exp' if `touse'
            if "`opt'"=="outlier" lab var `varlist' "Outlier"
            else                  lab var `varlist' "Inlier"
            exit
        }
        // subset (lts, lqs, lms)
        if "`opt'"=="subset" {
            qui replace `z' = (`e(depvar)' - `z')^2 if `touse'
            gen `typlist' `varlist' = (`z'<=e(q_h)) * `z'^0 if `touse'
                        // "* z^0" so that missing remains missing
            lab var `varlist' "H subset"
            exit
        }
        // weights (m, s, mm)
        qui replace `z' = (`e(depvar)' - `z') * `c' if `touse'
        if `"`subcmd'"'=="m" local obf mm_`e(obf)'_w
        else                 local obf mm_biweight_w
        mata: st_store(., "`z'", "`touse'", ///
            `obf'(st_data(., "`z'", "`touse'"), st_numscalar("e(k)")))
        gen `typlist' `varlist' = `z' if `touse'
        lab var `varlist' "RLS weights"
        exit
    }
    
    // scores and influence functions
    if `"`scores'"'!="" {
        _score_spec `anything', scores
        local varlist `s(varlist)'
        local typlist `s(typlist)'
    }
    else {
        capt confirm matrix e(V_modelbased)
        if _rc==1 exit _rc
        if _rc {
            di as err "e(V_modelbased) not found; cannot compute influence functions"
            exit 498
        }
        local varlist
        local typlist
        local k_eq = e(k_eq)
        forv i = 1/`k_eq' {
            tempname tmp
            local varlist `varlist' `tmp'
            local typlist `typlist' double
        }
    }
    if `:list sizeof varlist'==1 {
         qui _predict `typlist' `varlist' if `touse', xb nolabel
         if `ivar' {
             qui replace `varlist' = `varlist' + `U' if `touse'
         }
    }
    else {
        local i 0
        foreach v of local varlist {
            local ++i
            gettoken typ typlist : typlist
            qui _predict `typ' `v' if `touse', xb nolabel equation(#`i')
            if `i'==1 & `ivar' {
                qui replace `v' = `v' + `U' if `touse'
            }
        }
    }
    mata: rr_`subcmd'_scores()
    if `"`scores'"'!="" {
        if e(k_eq)==1 {
            lab var `varlist' "Scores"
            exit
        }
        local i 0
        foreach v of local varlist {
            local ++i
            lab var `v' "Scores of equation #`i'"
        }
        exit
    }
    local scores `varlist'
    tempname b
    matrix `b' = e(b)
    local p = colsof(`b')
    mata: st_matrixcolstripe("`b'", ("eq":+strofreal(1::`p'),J(`p',1,"_cons")))
    local 0 `"`anything'"'
    capt syntax newvarlist
    if _rc==1 exit _rc
    if _rc==0 {
        local p0 `p'
        local p: list sizeof varlist
        if `p'>`p0' {
            di as err "too many variables specified"
            exit 103
        }
        if `p'<`p0' {
            matrix `b' = `b'[1...,1..`p']
        }
    }
    _score_spec `anything', scores b(`b')
    local varlist `s(varlist)'
    local typlist `s(typlist)'
    if `userif'==0 {
        // restrict sample to e(sample) if user did not specify 'if' or 'in'
        qui replace `touse' = 0 if e(sample)!=1
    }
    local coln: colfullnames e(b)
    foreach v of local varlist {
        gettoken typ typlist : typlist
        gettoken lbl coln : coln
        if "`rifs'"!="" {
            qui gen `typ' `v' = . if `touse'
            lab var `v' `"RIF of _b[`lbl']"'
        }
        else {
            qui gen `typ' `v' = 0 if `touse'
            lab var `v' `"IF of _b[`lbl']"'
        }
    }
    if `userif' {
        // make sure that IFs (RIFs) are zero (missing) outside e(sample)
        qui replace `touse' = 0 if e(sample)!=1
    }
    if `ivar' {
        if `"`e(wexp)'"'!="" {
            tempvar wvar
            qui gen double `wvar' `e(wexp)' if `esample'
        }
        if `"`subcmd'"'!="ls" {
            tempname z c
            scalar `c' = cond(e(scale)==0, 0, 1 / e(scale))
            qui _predict double `z' if `esample', xb nolabel
            qui replace `z' = (`e(depvar)' - (`z'+`U')) * `c' if `esample'
            if `"`subcmd'"'=="m" local obf mm_`e(obf)'_phi
            else                 local obf mm_biweight_phi
            mata: st_store(., "`z'", "`esample'", ///
                `obf'(st_data(., "`z'", "`esample'"), st_numscalar("e(k)")))
            if "`wvar'"=="" local wvar `z'
            else {
                qui replace `wvar' = `wvar' * `z' if `esample'
            }
        }
    }
    mata: rr_IFs()
end

program predict_ls_U, sortpreserve
    args xb u esample
    if `"`e(wexp)'"' != "" {
        tempvar w
        qui gen double `w' `e(wexp)' if `esample'
    }
    else local w 1
    qui _predict double `xb' if `esample', xb nolabel
    sort `esample' `e(ivar)' `e(absorb)'
    qui by `esample' `e(ivar)' `e(absorb)': ///
        replace `u' = sum(`w'*(`e(depvar)' - `xb')) / sum(`w') if `esample'
    qui by `esample' `e(ivar)' `e(absorb)': replace `u' = `u'[_N]
end

program Hausman
    // syntax
    _parse comma lhs 0 : 0
    syntax [, CONStant COMmon keep(str) drop(str) noDetail noHEADer NOTABle ///
        Ftest post COEFTitle(passthru) * ]
    if "`detail'"!="" local notable notable // backward compatibility
    _get_diopts diopts options, `options'
    _get_eformopts, eformopts(`options') allowed(__all__)
    local diopts `s(eform)' `diopts'
    if `"`lhs'"'=="" local lhs .
    gettoken m1 lhs : lhs
    gettoken m2 lhs : lhs
    if `"`lhs'"'!="" {
        di as err `"{bf:`lhs'} not allowed"'
        exit 198
    }
    
    // model 1
    tempname ecurrent
    if `"`m1'"'!="." {
        _estimates hold `ecurrent', restore nullok
        qui estimates restore `m1'
    }
    if `"`e(cmd)'"'!="robreg" {
        di as error `"{bf:robreg hausman} not allowed after {bf:`e(cmd)'}"'
        exit 301
    }
    if `"`e(subcmd)'"'=="hausman" {
        di as error `"{bf:robreg hausman} not allowed after {bf:robreg hausman}"'
        exit 301
    }
    if `"`m2'"'=="" { // single model
        if `"`e(subcmd)'"'!="mm" {
            di as error "single model syntax only allowed after {bf:robreg mm}"
            exit 301
        }
        capt confirm matrix e(V)
        if _rc==1 exit _rc
        else if _rc {
            di as err "e(V) not found; cannot perform Hausman test"
            exit 498
        }
        mata: rr_hausman_mm()
    }
    else {
        mata: rr_hausman_get_minfo("1")
    }
    if `"`m1'"'!="." {
        _estimates unhold `ecurrent'
    }
    
    // model 2
    if `"`m2'"'!="" {
        if `"`m2'"'!="." {
            _estimates hold `ecurrent', restore nullok
            qui estimates restor `m2'
        }
        if `"`e(cmd)'"'!="robreg" {
            di as error `"{bf:robreg hausman} not allowed after {bf:`e(cmd)'}"'
            exit 301
        }
        if `"`e(subcmd)'"'=="hausman" {
            di as error `"{bf:robreg hausman} not allowed after {bf:robreg hausman}"'
            exit 301
        }
        mata: rr_hausman_get_minfo("2")
        
        // common xvars / sample / weights
        if "`common'"!="" {
            local xvars: list xvars1 & xvars2
        }
        else {
            local xvars: list xvars1 | xvars2
        }
        capt assert(`touse1'==`touse2')
        if _rc==1 exit _rc
        else if _rc {
            tempvar touse
            qui gen byte `touse' = `touse1'==1 | `touse2'==1
            di as txt "(samples are different; using joint sample across both models)"
        }
        else local touse `touse1'
        if `"`wtype1'"'!="" {
            tempvar wvar
            qui gen double `wvar' `wexp1' if `touse' 
        }
        
        // IFs
        qui predict double `IFs2' if `touse', ifs
        if `"`m2'"'!="." {
            _estimates unhold `ecurrent'
        }
        if `"`m1'"'!="." {
            _estimates hold `ecurrent', restore nullok
            qui estimates restor `m1'
        }
        qui predict double `IFs1' if `touse', ifs
        if `"`m1'"'!="." {
            _estimates unhold `ecurrent'
        }
        
        // compute test
        mata: rr_hausman_compute()
    }
    
    // display
    if "`header'"!="" & "`notable'"!="" {
        if "`post'"!="" {
            postrtoe
            return_clear
        }
        exit
    }
    _estimates hold `ecurrent', restore nullok
    postrtoe
    tempname rcurrent
    _return hold `rcurrent'
    if "`header'"=="" {
        hausman_header
    }
    if "`notable'"=="" {
        if `"`coeftitle'"'=="" local coeftitle coeftitle(Delta)
        di ""
        _coef_table, `coeftitle' `diopts'
    }
    if "`post'"!="" {
        _estimates unhold `ecurrent', not
    }
    else {
        _estimates unhold `ecurrent'
        _return restore `rcurrent'
    }
end

program hausman_header, rclass
    _coef_table_header
end

program return_clear, rclass
    local x
end

program Estimate, eclass
    // syntax
    gettoken subcmd 0 : 0, parse(", ")
    local refit = ("`subcmd'"=="_mm")
    if `refit' local subcmd "mm"
    local notallowed y touse n xvars xvars0
    foreach opt of local notallowed {
        local notallowedopts notallowedopts `opt'(passthru)
    }
    syntax varlist(fv ts) [if] [in] [pw fw iw] [, ///
        noCONStant nor2 Ivar(varname numeric) Absorb(varname numeric) ///
        UGENerate(name) NOUsave Usave replace ///
        vce(str) CLuster(varname) Ftest NOSE ///
        Level(passthru) all noHEADer NOTABle ///
        TOLerance(numlist >0 max=1) ///
        ITERate(integer `c(maxiter)') ///
        relax noquad nolog /// 
        `notallowedopts' * ]
    if "`usave'"!="" & "`nousave'"!="" {
        di as err "{bf:usave} and {bf:nousave} not both allowed"
        exit 198
    }
    foreach opt of local notallowed {
        if `"``opt''"'!="" {
            di as err "option {bf:`opt'()} not allowed"
            exit 198
        }
    }
    _get_diopts diopts options, `options'
    _get_eformopts, eformopts(`options') soptions allowed(__all__)
    local options `"`s(options)'"'
    c_local diopts `s(eform)' `level' `all' `header' `notable' `diopts'
    if "`tolerance'"=="" {
        if "`subcmd'"=="q" local tolerance 1e-8
        else               local tolerance 1e-10
    }
    if "`ivar'"!="" & "`constant'"!="" {
        di as err "{bf:ivar()} and {bf:noconstant} not both allowed"
        exit 198
    }
    if "`absorb'"!="" & "`constant'"!="" {
        di as err "{bf:absorb()} and {bf:noconstant} not both allowed"
        exit 198
    }
    if "`ivar'"!="" & "`absorb'"!="" {
        di as err "{bf:ivar()} and {bf:absorb()} not both allowed"
        exit 198
    }
    
    // VCE/SE
    if "`nose'"!="" {
        if `"`vce'"'!="" {
            di as err "{bf:nose} and {bf:vce()} not both allowed"
            exit 198
        }
        if "`cluster'"!="" {
            di as err "{bf:nose} and {bf:cluster()} not both allowed"
            exit 198
        }
        local novce novce
    }
    else if "`weight'"=="iweight" { // support for svy
        if `"`vce'"'!="" {
            di as err "{bf:vce()} not allowed with {bf:iweight}s"
            exit 198
        }
        if "`cluster'"!="" {
            di as err "{bf:cluster()} not allowed with {bf:iweight}s"
            exit 198
        }
        local novce novce
    }
    else if `"`vce'"'!="" {
        if "`cluster'"!="" {
            di as err "{bf:cluster()} and {bf:vce()} not both allowed"
            exit 198
        }
        gettoken vce cluster : vce
        if `:list sizeof cluster'==1 & ///
            substr("cluster", 1, max(2, strlen(`"`vce'"')))==`"`vce'"' {
            unab cluster : `cluster'
            local clustopt cluster(`cluster')
        }
        else if !(`"`cluster'"'=="" & ///
            `"`vce'"'==substr("robust", 1, max(1, strlen(`"`vce'"')))) {
            di as err "invalid {bf:vce()}"
            exit 198
        }
    }
    else if "`cluster'"!="" {
        local clustopt cluster(`cluster')
    }
    if "`novce'"=="" {
        if inlist("`subcmd'","lts","lqs","lms") {
            if `"`vce'"'!="" {
                di as err "{bf:vce()} not supported by {bf:robreg `subcmd'}"
                exit 198
            }
            if "`cluster'"!="" {
                di as err "{bf:cluster()} not supported by {bf:robreg `subcmd'}"
                exit 198
            }
            else local novce novce
        }
    }
    
    // estimation sample, variables, weights
    _fv_check_depvar `varlist', k(1)
    marksample touse
    if "`cluster'"!="" {
        markout `touse' `cluster', strok
    }
    if "`ivar'`absorb'"!="" {
        markout `touse' `ivar' `absorb', strok
        if "`ivar'"!="" local ivaropt ivar(`ivar')
        else            local ivaropt absorb(`absorb')
        if "`ugenerate'"!="" {
            local nousave nousave
            local usave
            if "`replace'"=="" {
                confirm new var `ugenerate'
            }
            tempvar UGEN
            qui gen double `UGEN' = .
            local ivaropt `ivaropt' ugen(`UGEN')
        }
        local ivaropt `ivaropt' `nousave' `usave'
    }
    else {
        local nousave
        local usave
        local ugenerate
    }
    _nobs `touse' [`weight'`exp']
    local n = r(N)
    gettoken y xvars : varlist
    if `refit' {
        local xvars `e(indepvars)'
    }
    else {
        if `:list sizeof xvars' {
            if inlist("`subcmd'","s","mm") {
                fvexpand `xvars' if `touse'
                local xvars0 xvars0(`r(varlist)')
            }
            _rmcoll `xvars' [`weight'`exp'] if `touse', `constant' expand
            local xvars `r(varlist)'
            local xvars: list uniq xvars
        }
        if "`xvars'"=="" & "`constant'"!="" {
            di as err "too few variables specified"
            exit 102
        }
    }
    if "`weight'"!="" {
        local wvar = strtrim(substr(`"`exp'"',2,.))
        capt confirm variable `wvar'
        if _rc==1 exit _rc
        if _rc {
            tempvar wvar
            qui gen double `wvar' `exp' if `touse'
        }
        else {
            unab wvar: `wvar', min(1) max(1)
        }
        local wgt [`weight'=`wvar']
    }
    
    // estimate and post results
    if "`novce'"=="" & "`ivar'"!="" {
        if "`cluster'"=="" {
            local cluster `ivar'
            local clustopt cluster(`cluster')
        }
        else if "`cluster'"!="`ivar'" {
            Panels_not_nested_in_clusters `ivar' `cluster' `touse'
        }
    }
    if inlist("`subcmd'","lqs","lts","lms") local cmd "lqs"
    else local cmd "`subcmd'"
    Estimate_`cmd' `subcmd' `refit' `wgt', y(`y') xvars(`xvars') `xvars0' ///
        touse(`touse') n(`n') `ivaropt' `constant' `r2' `clustopt' `ftest' ///
        `nose' `level' tolerance(`tolerance') iterate(`iterate') `relax' ///
        `quad' `log' `options'
    eret local cmd       "robreg"
    eret local subcmd    "`subcmd'"
    eret local predict   "robreg predict"
    eret local depvar    "`y'"
    eret local indepvars "`xvars'"
    eret local ivar      "`ivar'"
    eret local absorb    "`absorb'"
    eret local wtype     "`weight'"
    eret local wexp      `"`exp'"'
    eret local noconstant "`constant'"
    eret local nor2       "`r2'"
    eret local noquqd     "`quad'"
    if "`novce'"!="" exit
    if "`cluster'"!="" {
        eret local vce "cluster"
        eret local clustvar "`cluster'"
    }
    else {
        eret local vce "robust"
    }
    eret local vcetype "Robust"
    
    // ugenerate
    if "`ugenerate'"!="" {
        capt confirm new variable `ugenerate'
        if _rc==1 exit _rc
        if _rc drop `ugenerate'
        rename `UGEN' `ugenerate'
        lab var `ugenerate' "Fixed effect"
        eret local ugenerate "`ugenerate'"
    }
end

program Panels_not_nested_in_clusters, sortpreserve
    args ivar cluster touse
    capt bysort `touse' `ivar': assert(`cluster'==`cluster'[1]) if `touse'
    if _rc==9 {
        di as err "panels are not nested within clusters"
        exit 498
    }
    exit _rc
end

program Estimate_ls, eclass
    gettoken subcmd 0 : 0
    gettoken refit 0 : 0  // not used
    syntax [pw fw iw/], y(str) touse(str) n(str) [ xvars(str) ///
        noconstant nor2 ivar(str) absorb(str) ugen(str) NOUsave Usave ///
        cluster(str) ftest nose level(cilevel) ///
        tolerance(str) iterate(str) relax noquad nolog ]
    if `"`ivar'`absorb'"'!="" {
        if "`weight'"=="iweight" {
            di as err "{bf:iweight}s not allowed"
            exit 101
        }
        if "`usave'"=="" local nousave nousave // do not store FEs by default
    }
    mata: rr_ls()
    c_local xvars `xvars' // ivar()/absorb() may change omitted flags
end

program Estimate_q, eclass
    // syntax
    gettoken subcmd 0 : 0
    gettoken refit 0 : 0  // not used
    syntax [pw fw iw/], y(str) touse(str) n(str) [ xvars(str) ///
        noconstant nor2 cluster(str) ftest nose level(cilevel) ///
        tolerance(str) iterate(str) relax noquad nolog ///
        Quantile(numlist >0 <=100 max=1) ///
        FITted BOfinger ///
        init(name) ]
    if "`quantile'"==""  local quantile 0.5
    if `quantile'>=1     local quantile = `quantile'/100
    if `"`init'"'!="" { // custom starting values
        confirm matrix `init'
    }
    
    // estimate
    mata: rr_q()
end

program Estimate_m, eclass
    // syntax
    gettoken subcmd 0 : 0
    gettoken refit 0 : 0  // not used
    syntax [pw fw iw/], y(str) touse(str) n(str) [ xvars(str) ///
        noconstant nor2 cluster(str) ftest nose level(cilevel) ///
        ivar(str) absorb(str) ugen(str) NOUsave Usave ///
        tolerance(str) iterate(str) relax noquad nolog ///
        Huber BIweight BISquare ///
        EFFiciency(numlist max=1) K(numlist >0 max=1) ///
        Scale(numlist >0 max=1) UPDATEscale CENter ///
        init(str) ]
    if "`weight'"=="iweight" {
        if `"`ivar'`absorb'"'!="" {
            di as err "{bf:iweight}s not allowed"
            exit 101
        }
    }
    if "`bisquare'"!=""  local biweight biweight
    local obf `huber' `biweight'
    if "`obf'"=="" local obf "huber"
    if `: list sizeof obf'>1 {
        if "`bisquare'"!="" local obf `bisquare'
        else                local obf biweight
        di as err "{bf:huber} and {bf:`obf'} not both allowed"
        exit 198
    }
    if "`efficiency'"!="" & "`k'"!="" {
        di as err "{bf:efficiency()} and {bf:k()} not both allowed"
        exit 198
    }
    else if "`k'`efficiency'"=="" local efficiency 95
    if "`efficiency'"!="" {
        if "`obf'"=="huber" {
            if `efficiency'<63.7 | `efficiency'>99.9 {
                di as err "efficiency() invalid;" ///
                    " must be in [63.7,99.9] for Huber M"
                exit 125
            }
        }
        else {
            if `efficiency'<1 | `efficiency'>99.9 {
                di as err "efficiency() invalid;" ///
                    " must be in [1.0,99.9] for biweight M"
                exit 125
            }
        }
    }
    if `"`init'"'=="" local init "lad"
    if !inlist(`"`init'"', "lad", "ls") { // custom starting values
        confirm matrix `init'
        if `"`ivar'`absorb'"'!="" {
            di as err "{bf:init(}{it:matname}{bf:)} not allowed with {bf:ivar()} or {bf:absorb()}"
            exit 198
        }
    }
    
    // estimate
    mata: rr_m()
    eret local obf "`obf'"
    eret local center "`center'"
    eret local updatescale "`updatescale'"
    c_local xvars `xvars' // ivar()/absorb() may change omitted flags
end

program Estimate_s, eclass
    // syntax
    gettoken subcmd 0 : 0
    gettoken refit 0 : 0    // not used
    syntax [pw fw/], y(str) touse(str) n(str) [ xvars(str) xvars0(str) ///
        noconstant nor2 cluster(str) ftest nose level(cilevel) ///
        ivar(str) absorb(str) ugen(str) NOUsave Usave ///
        tolerance(str) iterate(str) relax noquad nolog ///
        bp(numlist >=1 <=50 max=1) K(numlist >0 max=1) ///
        noHAUSman ///
        m(str) ///
        Nsamp(numlist max=2) /// 
        RSTEPs(numlist int >=0 max=1) ///
        NKeep(numlist int >0 max=1) ///
        naive alt nostd ]
    if "`bp'"!="" & "`k'"!="" {
        di as err "{bf:bp()} and {bf:k()} not both allowed"
        exit 198
    }
    else if "`bp'`k'"=="" local bp 50
    parse_nsamp `nsamp'
    if "`rsteps'"=="" local rsteps 2
    if "`nkeep'"==""  local nkeep  5
    if "`naive'"!="" & "`alt'"!="" {
        di as err "{bf:naive} and {bf:alt} not both allowed"
        exit 198
    }
    
    // parsing of m() option
    parse_mopts `m'
    if "`m_vars'"!="" {
        fvexpand `m_vars' if `touse'
        local m_vars `r(varlist)'
        local m_vars: list uniq m_vars
        local m_vars0: list m_vars - xvars
        local m_vars: list m_vars & xvars
        if `: list sizeof m_vars0' {
            local m_vars0: list m_vars0 - xvars0
            if `: list sizeof m_vars0' {
                gettoken m_vars0 : m_vars0
                di as err `"variable {bf:`m_vars0'} not found in {it:indepvars}"'
                di as err "error in option {bf:m()}"
                exit 111
            }
        }
    }
    
    // estimate
    mata: rr_s()
    c_local xvars `xvars' // ivar()/absorb() may change omitted flags
end

program parse_nsamp
    if "`0'"=="" exit
    if `: list sizeof 0'==2 {
        gettoken alpha   0 : 0
        gettoken epsilon   : 0
        if "`alpha'"!="" {
            if `alpha'<=0 | `alpha'>=1 {
               di as err "{bf:nsamp()}: {it:alpha} must be in (0,1)"
               exit 198
            }
        }
        if "`epsilon'"!="" {
            if `epsilon'<=0 | `epsilon'>0.5 {
               di as err "{bf:nsamp()}: {it:epsilon} must be in (0,0.5]"
               exit 198
            }
        }
    }
    else if `0'<1 & `0'>0 {
        local alpha `0'
    }
    else {
        if `0'!=floor(`0') | `0'<1 {
            di as err "{bf:nsamp()}: {it:n} must be a positive integer"
            exit 198
        }
        local nsamp `0'
    }
    c_local nsamp `nsamp'
    c_local alpha `alpha'
    c_local epsilon `epsilon'
end

program parse_mopts
    syntax [varlist(default=none fv ts)] [, ///
        EFFiciency(numlist max=1) K(numlist >0 max=1) ]
    if "`efficiency'"!="" & "`k'"!="" {
        di as err "{bf:efficiency()} and {bf:k()} not both allowed"
        di as err "error in option {bf:m()}"
        exit 198
    }
    else if "`k'`efficiency'"=="" local efficiency 95
    if "`efficiency'"!="" {
        if `efficiency'<63.7 | `efficiency'>99.9 {
            di as err "efficiency() invalid; must be in [63.7,99.9]"
            di as err "error in option {bf:m()}"
            exit 125
        }
    }
    c_local m_vars `varlist'
    c_local m_efficiency `efficiency'
    c_local m_k `k'
end

program Estimate_mm, eclass
    // syntax
    gettoken subcmd 0 : 0
    gettoken refit 0 : 0
    syntax [pw fw/], y(str) touse(str) n(str) [ xvars(str) xvars0(passthru) ///
        noconstant nor2 cluster(str) ftest nose level(cilevel) ///
        tolerance(str) iterate(str) relax noquad nolog ///
        EFFiciency(numlist max=1) K(numlist >0 max=1) ///
        noHAUSman bp(passthru) Sopts(str asis) ]
    if "`efficiency'"!="" & "`k'"!="" {
        di as err "{bf:efficiency()} and {bf:k()} not both allowed"
        exit 198
    }
    else if "`k'`efficiency'"=="" local efficiency 85
    if "`efficiency'"!="" {
        if `efficiency'<1 | `efficiency'>99.9 {
            di as err "efficiency() invalid; must be in [1.0,99.9]"
            exit 125
        }
    }

    // s-estimate
    if `refit' {
        if `n'!=e(N) {
            di as err "something is wrong; estimation sample changed"
            exit 498
        }
    }
    else {
        capt n parse_sopts, `sopts'
        if _rc==1 exit _rc
        else if _rc {
            di as err "error in option {bf:sopts()}"
            exit _rc
        }
        if `"`bp'"'!="" {
            if `"`s_bp'"'!="" {
                di as err "{bf:bp()} and {bf:sopts(bf())} not both allowed"
                exit 198
            }
            local s_bp `"`bp'"'
            if `"`s_k'"'!="" {
                di as err "{bf:bp()} and {bf:sopts(k())} not both allowed"
                exit 198
            }
        }
        if `"`s_tol'"'==""   local s_tol   "tolerance(`tolerance')"
        if `"`s_iter'"'==""  local s_iter  "iterate(`iterate')"
        if `"`s_relax'"'=="" local s_relax "`relax'"
        if `"`s_quad'"'==""  local s_quad  "`quad'"
        if `"`s_log'"'==""   local s_log   "`log'"
        if "`weight'"!="" local wgt [`weight' = `exp']
        else              local wgt
        Estimate_s s 0 `wgt', y(`y') xvars(`xvars') `xvars0' ///
             touse(`touse') n(`n') nose `constant' `r2' ///
             `s_bp' `s_k' `s_tol' `s_iter' `s_relax' `s_quad' `s_log' `sopts'
        qui gen byte `touse' = e(sample)
    }
    
    // estimate
    mata: rr_mm()
end

program parse_sopts
    syntax [, ///
        bp(passthru) K(passthru) m(passthru) ///
        Nsamp(passthru) RSTEPs(passthru) NKeep(passthru) naive alt nostd ///
        TOLerance(passthru) ITERate(passthru) relax noquad noLOG ]
    if "`bp'"!="" & "`k'"!="" {
        di as err "{bf:bp()} and {bf:k()} not both allowed"
        exit 198
    }
    if "`naive'"!="" & "`alt'"!="" {
        di as err "{bf:naive} and {bf:alt} not both allowed"
        exit 198
    }
    c_local s_bp    `bp'
    c_local s_k     `k'
    c_local s_tol   `tolerance'
    c_local s_iter  `iterate'
    c_local s_relax `relax'
    c_local s_quad  `quad'
    c_local s_log   `log'
    c_local sopts   `m' `nsamp' `rsteps' `nkeep' `naive' `alt' `std'
end

program ReEstimate_mm // returns diopts
    if !(`"`e(cmd)'"'=="robreg" & inlist(`"`e(subcmd)'"', "mm", "s") & ///
        `"`e(prefix)'"'=="") {
        di as err "last estimates not found or invalid"
        exit 301
    }
    else if `"`e(ivar)'`e(absorb)'"'!="" {
        di as err "MM after S with option {bf:ivar()} or {bf:absorb()} not supported"
        exit 498
    }
    
    // syntax
    syntax [, ///
        EFFiciency(passthru) K(passthru) noHAUSman ///
        Ftest Level(passthru) all noHEADer NOTABle ///
        TOLerance(passthru) ITERate(passthru) relax noquad noLOG * ]
    if `"`level'"'=="" {
        if `"`e(level)'"'!="" {
            local level level(`e(level)')
        }
    }
    _get_diopts diopts options, `options'
    _get_eformopts, eformopts(`options') allowed(__all__)
    c_local diopts `s(eform)' `level' `all' `header' `notable' `diopts'
    local options `efficiency' `k' `hausman' `ftest' `level' /*
        */ `tolerance' `iterate' `relax' `quad' `log'
    
    // collect settings
    local anything `e(depvar)' if e(sample) // skip indepvars
    if `"`e(wtype)'"'!="" {
        local anything `anything' [`e(wtype)' `e(wexp)']
    }
    if `"`e(vce)'"'=="cluster" local vce vce(cluster `e(clustvar)')
    else if `"`e(vce)'"'!=""   local vce vce(`e(vce)')
    else                       local vce nose
    local options `e(noconstant)' `e(nor2)' `vce' `options'
    
    // estimate
    Estimate _mm `anything', `options'
end

program Estimate_lqs, eclass
    // syntax
    gettoken subcmd 0 : 0
    gettoken refit 0 : 0  // not used
    if "`subcmd'"=="lts" {
        local ltsopts CSTEPs(numlist int >=0 max=1) NKeep(numlist int >0 max=1)
    }
    if "`subcmd'"!="lms" {
        local bp bp(numlist >=1 <=50 max=1)
    }
    syntax [pw fw/], y(str) touse(str) n(str) [ xvars(str) ///
        noconstant nor2 cluster(str) ftest nose level(cilevel) ///
        tolerance(str) iterate(str) relax noquad nolog ///
        `bp' Nsamp(numlist max=2) `ltsopts' naive alt nostd ]
    if "`bp'"==""     local bp 50
    parse_nsamp `nsamp'
    if "`csteps'"=="" local csteps 2
    if "`nkeep'"==""  local nkeep  10
    if "`naive'"!="" & "`alt'"!="" {
        di as err "{bf:naive} and {bf:alt} not both allowed"
        exit 198
    }
    
    // deactivate VCE
    local se nose
    
    // estimate
    mata: rr_lqs()
end

version 11
mata:
mata set matastrict on

/*---------------------------------------------------------------------------*/
// helper functions called by ado
/*---------------------------------------------------------------------------*/

// copy fixed effects

void rr_fillin_u()
{
    string scalar  ivar
    real colvector id
    real matrix    u
    
    ivar = st_global("e(ivar)") + st_global("e(absorb)")
    id = st_data(., ivar, st_local("esample"))
    u = st_matrix("e(u)")
    st_store(., st_local("U"), st_local("esample"),
        mm_crosswalk(id, u[,1], u[,2]))
}

// IFs

void rr_IFs()
{
    real scalar      p, i, k, cons, neq, touse
    string rowvector IFs, xvars
    real matrix      scores, Ginv, H, X
    pragma unset scores
    pragma unset X
    
    touse = st_varindex(st_local("touse"))
    st_view(scores, ., st_local("scores"), touse)
    if (rows(scores)==0) return // no observations selected
    IFs     = tokens(st_local("varlist"))
    p       = length(IFs)
    Ginv    = st_matrix("e(V_modelbased)")
    cons    = st_global("e(noconstant)")==""
    neq     = st_numscalar("e(k_eq)")
    xvars   = tokens(st_global("e(indepvars)"))
    k       = length(xvars)
    if (k) _rr_IFs_X(X, xvars, touse)
    H = J(rows(scores), 0, .)
    for (i=1;i<=neq;i++) {
        if (i==1 | i<neq) {
            if (k)    H = H, scores[,i] :* X
            if (cons) H = H, scores[,i]
        }
        else H = H, scores[,i]
    }
    H = (H * Ginv')[|1,1 \ .,p|]
    if (st_local("subcmd")=="q") {
        H = H :- st_matrix("e(IFoffset)")[|1 \ p|]
    }
    if (st_local("rifs")!="") {
        H = H * st_numscalar("e(N)") :+ st_matrix("e(b)")[|1 \ p|]
    }
    st_store(., IFs, touse, H)
}

void _rr_IFs_X(real matrix X, string rowvector xvars, real scalar touse)
{
    real scalar    esamp
    string scalar  ivar
    real colvector id, w
    real rowvector xmeans
    
    // raw data if not ivar() or absorb()
    ivar = st_global("e(ivar)") + st_global("e(absorb)")
    if (ivar=="") {
        st_view(X, ., xvars, touse)
        return
    }
    
    // transformed X if ivar() or absorb()
    esamp = st_varindex(st_local("esample"))
    id = st_data(., ivar, esamp)
    if (st_local("wvar")=="") w = 1
    else w = st_data(., st_local("wvar"), esamp)
    X = st_data(., xvars, esamp)
    xmeans = mean(X, w)
    X = rr_demean(_mm_areg_g(id, 1), X, w)
    if (st_local("userif")=="1") {
        // note: touse is a subsample of esample at this point
        X = select(X, st_data(., touse, esamp))
    }
    X = X :+ xmeans
}

// Hausman tests

void rr_hausman_get_minfo(string scalar id)
{
    real scalar      k
    string rowvector tmp
    
    // checks
    if (st_global("e(prefix)")!="") {
        printf("{err}%s: Hausman test not supported after {bf:%s} prefix\n", 
            st_local("m"+id), st_global("e(prefix)"))
        exit(error(498))
    }
    // estimation sample
    st_local("touse"+id, tmp = st_tempname())
    stata(sprintf("qui gen byte %s = e(sample)==1", tmp))
    // coefficients
    st_local("b"+id, tmp = st_tempname())
    st_matrix(tmp, st_matrix("e(b)"))
    st_local("omit"+id, tmp = st_tempname())
    st_matrix(tmp, st_matrix("e(omit)"))
    // predictors
    tmp = st_global("e(indepvars)")
    st_local("xvars"+id, tmp)
    k = length(tokens(tmp)) + (st_global("e(noconstant)")=="")
    st_local("nocons"+id, st_global("e(noconstant)"))
    // tempnames for IFs
    st_local("IFs"+id, tmp = invtokens(st_tempname(k)))
    // vcetype and weights
    st_local("vce"+id, st_global("e(vce)"))
    st_local("vcetype"+id, st_global("e(vcetype)"))
    st_local("clustvar"+id, st_global("e(clustvar)"))
    st_local("wexp"+id, st_global("e(wexp)"))
    st_local("wtype"+id, st_global("e(wtype)"))
}

void rr_hausman_compute()
{
    real scalar      i, cons, cons1, cons2, k, k1, k2, j1, j2, fw, N_clust,
                     p, N, df, df_r, chi2
    string rowvector opts, keep, drop
    string colvector xvars, xvars1, xvars2
    string scalar    touse
    real colvector   q1, p1, q2, p2, b, w, omit1, omit2
    transmorphic colvector clust
    real matrix      IF, V, j
    string matrix    cs
    
    // checks
    opts = ("vce", "vcetype", "clustvar", "wexp", "wtype")
    for (i=length(opts); i; i--) {
        if (st_local(opts[i]+"1")!=st_local(opts[i]+"2")) {
            printf("{err}e(%s) different between models; cannot" + 
                " perform Hausman test\n", opts[i])
            exit(error(498))
        }
    }
    
    // select terms
    xvars = tokens(st_local("xvars"))' // variables that are in both models
    keep  = tokens(st_local("keep"))
    drop  = tokens(st_local("drop"))
    k = length(xvars)
    if (k & length(keep)) {
        xvars = select(xvars, rowsum(strmatch(xvars, keep)))
        k = length(xvars)
    }
    if (k & length(drop)) {
        xvars = select(xvars, !rowsum(strmatch(xvars, drop)))
        k = length(xvars)
    }
    cons  = (st_local("constant")!="")
    cons1 = (st_local("nocons1")=="")
    cons2 = (st_local("nocons2")=="")
    if (!cons1 & !cons2) cons = 0
    if (!(k+cons)) {
        display("{err}must select at least 1 coefficient;" + 
            " cannot perform Hausman test")
        exit(error(498))
    }
    xvars1 = tokens(st_local("xvars1"))'
    k1 = length(xvars1)
    if (k & k1) {
        if (xvars==xvars1) {; q1 = p1 = 1::k1; j1 = k1; }
        else {
            q1 = p1 = J(k,1,.)
            j1 = 0
            for (i=1;i<=k;i++) { // (not very efficient)
                j = select(1::k1, xvars1:==xvars[i])
                if (!length(j)) continue
                j1++
                q1[j1] = i
                p1[j1] = j
            }
            if (j1) {; q1 = q1[|1\j1|]; p1 = p1[|1\j1|]; }
            else       q1 = p1 = J(0,1,.)
        }
    }
    else {; q1 = p1 = J(0,1,.); j1 = 0; }
    xvars2 = tokens(st_local("xvars2"))'
    k2 = length(xvars2)
    if (k & k2) {
        if (xvars==xvars2) {; q2 = p2 = 1::k2; j2 = k2; }
        else {
            q2 = p2 = J(k,1,.)
            j2 = 0
            for (i=1;i<=k;i++) { // (not very efficient)
                j = select(1::k2, xvars2:==xvars[i])
                if (!length(j)) continue
                j2++
                q2[j2] = i
                p2[j2] = j
            }
            if (j2) {; q2 = q2[|1\j2|]; p2 = p2[|1\j2|]; }
            else       q2 = p2 = J(0,1,.)
        }
    }
    else {; q2 = p2 = J(0,1,.); j2 = 0; }
    omit1 = omit2 = J(k,1,1)
    if (j1) omit1[q1] = st_matrix(st_local("omit1"))[p1]'
    if (j2) omit2[q2] = st_matrix(st_local("omit2"))[p2]'
    df = k - sum(omit1:&omit2) // (both omitted/absent)
    if (cons) {
        k = k + 1
        df = df + 1
        if (cons1) {
            j1 = j1 + 1
            q1 = q1 \ k
            p1 = p1 \ (k1+1)
        }
        if (cons2) {
            j2 = j2 + 1
            q2 = q2 \ k
            p2 = p2 \ (k2+1)
        }
    }
    
    // number of parameters (not really clear how to do this best; we 
    // just use the max between models of the number of non-omitted
    // first-equation parameters)
    if (k1) k1 = k1 - sum(st_matrix(st_local("omit1"))[|1\k1|]:==1)
    if (k2) k2 = k2 - sum(st_matrix(st_local("omit2"))[|1\k2|]:==1)
    p = max((k1+cons1, k2+cons2))
    
    // obtain b and IFs
    touse = st_local("touse")
    b = J(k,1,0)
    if (j1) b[q1] = st_matrix(st_local("b1"))[p1]'
    if (j2) b[q2] = b[q2] - st_matrix(st_local("b2"))[p2]'
    IF = J(rows(st_data(., touse, touse)), k, 0)
    if (j1) IF[,q1] = st_data(., tokens(st_local("IFs1"))[p1], touse)
    if (j2) IF[,q2] = IF[,q2] - st_data(., tokens(st_local("IFs2"))[p2], touse)
    
    // compute V and perform test
    w = rr_wgt(st_local("wtype1"), st_local("wvar"), touse, fw=0)
    if (fw) N = colsum(w)
    else    N = rows(IF)
    clust = rr_clust(st_local("clustvar1"), touse)
    V = rr_VCE(IF, w, fw, p, N, clust, N_clust=.)
    chi2 = b' * invsym(V) * b
    
    // return results
    st_rclear()
    if (st_local("vce1")=="cluster") df_r = max((0,N_clust-1))
    else                             df_r = max((0,N-p))
    if (st_local("ftest")!="") {
        st_numscalar("r(p)", Ftail(df, df_r, chi2 / df))
        st_numscalar("r(F)", chi2 / df)
    }
    else {
        st_numscalar("r(p)", chi2tail(df, chi2))
        st_numscalar("r(chi2)", chi2)
    }
    st_numscalar("r(df_m)", df)
    cs = (length(xvars) ? xvars : J(0,1,"")) \ (cons ? "_cons" : J(0,1,""))
    cs = (J(k,1,""), cs)
    st_matrix("r(V)", V)
    st_matrixcolstripe("r(V)", cs)
    st_matrixrowstripe("r(V)", cs)
    st_matrix("r(b)", b')
    st_matrixcolstripe("r(b)", cs)
    st_global("r(wexp)", st_local("wexp1"))
    st_global("r(wtype)", st_local("wtype1"))
    if (st_local("vce1")=="cluster") {
        st_global("r(clustvar)", st_local("clustvar1"))
        st_numscalar("r(N_clust)", N_clust)
    }
    st_numscalar("r(df_r)", df_r)
    st_global("r(vcetype)", st_local("vcetype1"))
    st_global("r(vce)", st_local("vce1"))
    st_numscalar("r(N)", N)
    st_global("r(cmd)", "robreg")
    st_global("r(subcmd)", "hausman")
    st_global("r(title)", sprintf("Hausman test of %s against %s", 
        st_local("m1"), st_local("m2")))
}

void rr_hausman_mm()
{
    string rowvector keep, drop
    string colvector xvars
    real scalar      k, df, chi2
    real colvector   p, b
    real matrix      V, R
    string matrix    cs
    
    // select terms
    xvars = tokens(st_global("e(indepvars)"))'
    keep  = tokens(st_local("keep"))
    drop  = tokens(st_local("drop"))
    if ((k=length(xvars))) {
        if (length(keep)) p = rowsum(strmatch(xvars, keep)):!=0
        else              p = J(k, 1, 1)
        if (length(drop)) p = p :& !rowsum(strmatch(xvars, drop))
    }
    else p = J(0,1,.)
    if (st_global("e(noconstant)")=="") {
        if (st_local("constant")!="") p = p \ 1
        else                          p = p \ 0
    }
    k = sum(p)
    if (!k) {
        display("{err}must select at least 1 coefficient;" + 
            " cannot perform Hausman test")
        exit(error(498))
    }
    df = sum(select(st_matrix("e(omit)")[|1 \ rows(p)|]',p):==0)
    p  = select(1::2*rows(p)+1, p \ p \ 0)
    
    // compute Hausman test
    b    = st_matrix("e(b)")[p]'
    V    = st_matrix("e(V)")[p,p]
    R    = I(k), -I(k)
    b    = R * b
    V    = R * V * R'
    chi2 = b' * invsym(V) * b
    
    // return results
    st_rclear()
    if (st_local("ftest")!="") {
        st_numscalar("r(p)", Ftail(df, st_numscalar("e(df_r)"), chi2 / df))
        st_numscalar("r(F)", chi2 / df)
    }
    else {
        st_numscalar("r(p)", chi2tail(df, chi2))
        st_numscalar("r(chi2)", chi2)
    }
    st_numscalar("r(df_m)", df)
    cs = st_matrixcolstripe("e(b)")[p[|1\k|],]
    cs = (J(k,1,""), cs[,2])
    st_matrix("r(V)", V)
    st_matrixcolstripe("r(V)", cs)
    st_matrixrowstripe("r(V)", cs)
    st_matrix("r(b)", b')
    st_matrixcolstripe("r(b)", cs)
    st_numscalar("r(df_r)", st_numscalar("e(df_r)"))
    st_numscalar("r(N)", st_numscalar("e(N)"))
    st_global("r(wexp)", st_global("e(wexp)"))
    st_global("r(wtype)", st_global("e(wtype)"))
    if (st_global("e(vce)")=="cluster") {
        st_global("r(clustvar)", st_global("e(clustvar)"))
        st_numscalar("r(N_clust)", st_numscalar("e(N_clust)"))
    }
    st_global("r(vcetype)", st_global("e(vcetype)"))
    st_global("r(vce)", st_global("e(vce)"))
    st_global("r(subcmd)", "hausman")
    st_global("r(cmd)", "robreg")
    st_global("r(title)", "Hausman test of MM against S")
}

/*---------------------------------------------------------------------------*/
// main system
/*---------------------------------------------------------------------------*/

struct rr {
    // main
    string scalar    cmd // name of estimator
    real scalar      N, p, cons, df, fw, wsum
    struct rr_fit scalar f
    // covariates
    string rowvector xvars0, xvars
    real rowvector   xindx, omit
    // ivar
    real scalar      ivar   // 1 ivar(), 2 absorb(), 0 else
    real scalar      usave  // 1 save in e(), 2 generate, 0 do not save FEs
    real colvector   id
    real scalar      N_g, corr
    struct mm_areg_struct_g scalar ginfo
    // settings of robust estimators
    real scalar      k, bp, eff, delta
    string scalar    obf 
    real scalar      center, update
    // starting values
    string scalar    init
    real scalar      s_init
    real colvector   b_init
    // optimization
    real scalar      qd, dev
    real scalar      maxiter, tol, relax, dots
    // subsampling
    real scalar      nsamp, alpha, eps, rsteps, csteps, nkeep, nostd
    real scalar      smpl // 0 nonsingular, 1 naive, 2 alt
    // R2
    real scalar      r2, scale0, b0
    real rowvector   R2
    // VCE
    real scalar      se, vce, cilevel, ftest
    real scalar      N_clust
    real matrix      V, Ginv
    transmorphic colvector clust
    // Hausman tests
    real scalar      hm, hm_chi2, hm_p
    // additional object for quantile regression
    real scalar      q, sdev, sdev0, bwidth, bofinger, kbwidth
    string scalar    denmethod, kernel
    real colvector   b_lo, b_up
    real rowvector   IFoffset
    // additional objects for M-S algorithm in robreg s
    string rowvector x1             // names of variables in X1 (M part)
    real rowvector   x1id, x2id     // indices of variables in X1 and X2
    real scalar      p1, p2, cons2  // cols in X1 and X2; add cons toX2
    real scalar      k1, eff1       // tuning constant/efficiency of M part
    // additional objects for robreg mm
    real scalar      kS, effS, b0S
    real matrix      bS
    // additional objects for robreg lms/lqs/lts
    real scalar      h, q_h, h0, c, s0 
}

struct rr_fit {
    real scalar      scale
    real colvector   b, W, u
    real scalar      iter, converged
}

struct rr scalar rr_setup(real colvector y, real matrix X, 
    real colvector w)
{
    string scalar    touse
    struct rr scalar S
    
    // estimators
    S.cmd     = st_local("subcmd")
    
    // data
    touse     = st_local("touse")
    y         = st_data(., st_local("y"), touse )
    w         = rr_wgt(st_local("weight"), st_local("exp"), touse, S.fw=0)
    S.xvars0  = tokens(st_local("xvars"))
    S.xvars   = rr_st_view(X, S.xvars0, touse, S.xindx, S.omit)
    S.p       = length(S.xvars)
    S.cons    = (st_local("constant")=="")
    S.N       = strtoreal(st_local("n"))
    S.ivar    = (st_local("ivar")!="") + 2*(st_local("absorb")!="")
    if (S.ivar) {
        S.usave = (st_local("nousave")=="") + (st_local("ugen")!="")*2
        if   (S.ivar==1) S.id = st_data(., st_local("ivar"), touse)
        else S.id = st_data(., st_local("absorb"), touse)
        S.ginfo = _mm_areg_g(S.id, 1) // build group info
        S.N_g = rows(S.ginfo.levels)
        S.df = S.N - S.p - S.N_g
    }
    else S.df = S.N - S.p - S.cons
    S.clust   = rr_clust(st_local("cluster"), touse)
    
    // flags for optional computations
    S.se      = (st_local("se")=="")
    S.vce     = (st_local("weight")!="iweight") & S.se
    S.cilevel = strtoreal(st_local("level"))
    S.ftest   = (st_local("ftest")!="")
    S.hm      = (st_local("hausman")=="") & S.vce & S.p
    S.r2      = (st_local("r2")=="")
    
    // settings for robust estimators
    S.k       = strtoreal(st_local("k"))
    S.eff     = strtoreal(st_local("efficiency"))
    S.bp      = strtoreal(st_local("bp"))
    S.center  = (st_local("center")!="")
    S.update  = (st_local("updatescale")!="")
    S.obf     = st_local("obf")
    S.init    = st_local("init")
    S.nsamp   = strtoreal(st_local("nsamp"))
    S.alpha   = strtoreal(st_local("alpha"))
    S.eps     = strtoreal(st_local("epsilon"))
    S.rsteps  = strtoreal(st_local("rsteps"))
    S.csteps  = strtoreal(st_local("csteps"))
    S.nkeep   = strtoreal(st_local("nkeep"))
    S.smpl    = (st_local("naive")!="") + (st_local("alt")!="")*2
    S.nostd   = (st_local("std")!="")
    
    // optimization
    S.qd      = (st_local("quad")=="")
    S.dev     = 1
    S.maxiter = strtoreal(st_local("iterate"))
    S.tol     = strtoreal(st_local("tolerance"))
    S.relax   = (st_local("relax")!="")
    S.dots    = (st_local("log")=="")
    
    // return
    return(S)
}

// read weights and set fw

real colvector rr_wgt(string scalar w, string scalar wvar, 
    string scalar touse, real scalar fw)
{
    if (w=="") return(1) // no weights
    if (w=="fweight") fw = 1
    return(st_data(., wvar, touse))
}

// read clustvar (can be numeric or string)

transmorphic colvector rr_clust(string scalar clust, string scalar touse)
{
    if (clust=="") return(J(0, 1, .)) // no clustvar
    if (st_isstrvar(clust)) return(st_sdata(., clust, touse))
    return(st_data(., clust, touse))
}

// import covariates into Mata excluding omitted terms (and return updated 
// varlist) (in Stata 16, data could be read directly using -set fvbase off-)

string rowvector rr_st_view(real matrix X, string rowvector xvars, 
    string scalar touse, real rowvector indx, real rowvector omit)
{
    real matrix    X0
    pragma unset   X0
    
    indx = rr_indx_non_omitted(xvars, omit) // fills in 'omit'
    if (!length(indx)) {
        X = J(rows(st_data(., touse, touse)), 0, .)
        return(J(1,0,""))
    }
    st_view(X0, ., xvars, touse)
    st_subview(X, X0, ., indx)
    return(xvars[indx])
}

real rowvector rr_indx_non_omitted(string rowvector xvars, real rowvector omit)
{   // based on suggestion by Jeff Pitblado
    real scalar   c, k
    string scalar tm

    c = cols(xvars)
    if (c==0) return(J(1, 0, .))
    tm = st_tempname()
    st_matrix(tm, J(1, c, 0))
    st_matrixcolstripe(tm, (J(c, 1, ""), xvars'))
    stata(sprintf("_ms_omit_info %s", tm))
    omit = st_matrix("r(omit)")
    k = st_numscalar("r(k_omit)")
    if (k==0) return(1..c)
    if (k==c) return(J(1, 0, .))
    return(select(1..c, omit:==0))
}

// exclude additional omitted terms detected during estimation

void rr_update_omit(real matrix X, struct rr scalar S, real scalar k_omit, 
    real colvector omit0, | real matrix X1, real matrix X2)
{
    real rowvector omit
    real colvector p
    
    if (!k_omit) return
    if (!S.p)    return
    omit = omit0[|1\S.p|]'
    S.p  = S.p  - k_omit
    S.df = S.df + k_omit
    S.hm = S.hm & S.p
    S.omit[S.xindx] = omit
    rr_put_omit(S.xvars0, select(S.xindx, omit))
    p = select(1..cols(omit), !omit)
    if (length(p)==0) p = J(1,0,.)
    S.xvars = S.xvars[p]
    S.xindx = S.xindx[p]
    if (isview(X)) st_subview(X, X, ., p)
    else           X = X[,p]
    if (cols(X1)) {
        if (isview(X1)) st_subview(X1, X1, ., p)
        else            X1 = X1[,p]
    }
    if (cols(X2)) {
        if (isview(X2)) st_subview(X2, X2, ., p)
        else            X2 = X2[,p]
    }
    p = p, cols(omit) + 1
    if (length(S.f.b))    S.f.b    = S.f.b[p]
    if (length(S.b_init)) S.b_init = S.b_init[p]
    if (cols(S.Ginv))     S.Ginv   = S.Ginv[p,p]
}

void rr_put_omit(string rowvector xvars0, real rowvector p)
{   // add o. flags to additional omitted terms; also updates local xvars
    real scalar   i, k
    string scalar s

    k = length(p)
    for (i=1; i<=k; i++) {
        s = xvars0[p[i]]
        printf("{txt}note: {bf:%s} omitted because of collinearity.\n", s)
        stata("_ms_put_omit " + s)
        s = st_global("s(ospec)")
        if (s=="") continue // _ms_put_omit failed
        xvars0[p[i]] = s
    }
    st_local("xvars", invtokens(xvars0))
}

// insert omitted terms into b and V

void rr_isrtomitted(struct rr scalar S)
{
    real scalar k
    
    if (length(S.xvars0)==length(S.xindx)) return
    _rr_isrtomitted_b(S.f.b, S.xindx, S.xvars0)
    if (length(S.b_init))   _rr_isrtomitted_b(S.b_init, S.xindx, S.xvars0)
    if (length(S.b_lo))     _rr_isrtomitted_b(S.b_lo, S.xindx, S.xvars0)
    if (length(S.b_up))     _rr_isrtomitted_b(S.b_up, S.xindx, S.xvars0)
    if (length(S.IFoffset)) {
        _transpose(S.IFoffset)
        _rr_isrtomitted_b(S.IFoffset, S.xindx, S.xvars0)
        _transpose(S.IFoffset)
    }
    if (!S.se) return
    k = 1 + (S.cmd=="mm")
    _rr_isrtomitted_V(S.Ginv, S.xindx, S.xvars0, S.cons, k)
    if (S.vce) _rr_isrtomitted_V(S.V, S.xindx, S.xvars0, S.cons, k)
}

void _rr_isrtomitted_b(real colvector b, real rowvector indx,
    string rowvector xvars0)
{
    real scalar    p0, p
    real colvector b0
    
    p0 = length(xvars0)
    p  = length(indx)
    if (p==p0) return
    b0 = J(p0, 1, 0)
    if (rows(b)>p) { // b has extra rows, e.g. _cons
        if (p) b0[indx] = b[|1\p|]
        b0 = b0 \ b[|p+1\.|]
    }
    else if (p) b0[indx] = b
    swap(b, b0)
}

void _rr_isrtomitted_V(real matrix V, real rowvector indx,
    string rowvector xvars0, real scalar cons, real scalar k)
{
    real scalar    p0, p, p1, i
    real rowvector q
    real matrix    V1
    
    p0 = length(xvars0)
    p  = length(indx)
    if (p==p0) return
    p1 = rows(V) - k*(p+cons)    // extra element(s) (i.e. scale)
    p0 = p0 + cons
    q = J(1,0,.)
    for (i=1;i<=k;i++) q = (q, (i-1)*p0 :+ (indx, (cons ? p0 : J(1,0,.))))
    if (p1)            q = q, k*p0 :+ (1..p1)
    V1 = J(k*p0+p1, k*p0+p1, 0)
    V1[q,q] = V
    swap(V, V1)
}

// post results in e()

void rr_post(struct rr scalar S)
{
    string scalar  bnm, Vnm
    string matrix  cstripe
    
    // must store S.f.u before running eret post
    if (S.usave==2) {
        st_store(., st_local("ugen"), st_local("touse"), S.f.u)
    }
    
    // post b, V, and Ginv
    if (S.cons) S.omit = (S.omit, 0)
    cstripe =  (S.xvars0, (S.cons ? "_cons" : J(1,0,"")))'
    bnm = st_tempname()
    if (S.cmd=="mm") {
        S.omit = (S.omit, S.omit, 0)
        st_matrix(bnm, (S.f.b \ S.bS \ S.f.scale)')
        cstripe = (J(rows(cstripe), 1, "MM"), cstripe) \
                  (J(rows(cstripe), 1, "S"),  cstripe) \
                  ("scale", "_cons")
    }
    else if (S.cmd=="s") {
        S.omit = (S.omit, 0)
        st_matrix(bnm, (S.f.b \ S.f.scale)')
        cstripe = (J(rows(cstripe), 1, "S"), cstripe) \
                  ("scale", "_cons")
    }
    else {
        st_matrix(bnm, S.f.b')
        cstripe = (J(rows(cstripe), 1, ""), cstripe)
    }
    st_matrixcolstripe(bnm, cstripe)
    if (S.se) {
        Vnm = st_tempname()
        if (S.vce) st_matrix(Vnm, S.V)
        else       st_matrix(Vnm, S.Ginv)
        st_matrixcolstripe(Vnm, cstripe)
        st_matrixrowstripe(Vnm, cstripe)
    }
    stata(sprintf("eret post %s %s", bnm, Vnm) +
        ", esample(\`touse') depname(\`depname') obs(\`n')")
    st_matrix("e(omit)", S.omit)
    st_matrixcolstripe("e(omit)", cstripe)
    st_numscalar("e(k_omit)", sum(S.omit))
    if (S.se) {
        st_matrix("e(V_modelbased)", S.Ginv)
        st_matrixcolstripe("e(V_modelbased)", cstripe)
        st_matrixrowstripe("e(V_modelbased)", cstripe)
        st_numscalar("e(level)", S.cilevel)
        if (S.vce) {
            st_numscalar("e(rank)", rank(S.V))
            rr_post_modeltest(S)
        }
        else st_numscalar("e(rank)", rank(S.Ginv))
    }
    
    // standard scalars and macros
    st_numscalar("e(k_eq)", 1 + (S.cmd=="s") + 2*(S.cmd=="mm"))
    st_numscalar("e(k_eform)", 1 + (S.cmd=="s") + 2*(S.cmd=="mm"))
    st_numscalar("e(scale)", S.f.scale)
    st_numscalar("e(df_m)", S.p)
    if (S.N_clust<.) {
        st_numscalar("e(N_clust)", S.N_clust)
        st_numscalar("e(df_r)", S.N_clust-1)
    }
    else st_numscalar("e(df_r)", S.df)
    if (S.ivar) {
        st_numscalar("e(N_g)", S.N_g)
        st_numscalar("e(g_avg)", mean(S.ginfo.n))
        st_numscalar("e(g_min)", min(S.ginfo.n))
        st_numscalar("e(g_max)", max(S.ginfo.n))
        st_numscalar("e(corr)", S.corr)
        if (S.usave==1) {
            st_matrix("e(u)", (S.ginfo.levels, (S.f.u[S.ginfo.p])[S.ginfo.idx]))
            st_matrixcolstripe("e(u)", (J(2,1,""),("level","u")'))
        }
        else if (S.usave==2) {
            // record min and max of u for minimal check in predict
            st_matrix("e(uminmax)", minmax(S.f.u), "hidden")
        }
    }
    
    // additions depending on estimator
    if (S.cmd=="ls") {
        st_global("e(title)", "LS regression")
        if (S.r2) {
            st_matrix("e(b0)", S.b0)
            st_matrixcolstripe("e(b0)", ("", "_cons"))
            st_numscalar("e(scale0)"  , S.scale0)
            st_numscalar("e(r2)"      , S.R2)
        }
    }
    else if (S.cmd=="q") {
        st_global("e(title)", sprintf("%g Quantile regression", S.q))
        st_numscalar("e(q)", S.q)
        st_numscalar("e(sum_adev)", S.sdev)
        st_numscalar("e(iterations)", S.f.iter)
        st_numscalar("e(converged)", S.f.converged)
        st_matrix("e(b_init)", S.b_init')
        st_matrixcolstripe("e(b_init)", st_matrixcolstripe("e(b)"))
        if (S.r2) {
            st_matrix("e(b0)", S.b0)
            st_matrixcolstripe("e(b0)", ("", "_cons"))
            st_numscalar("e(sum_rdev)", S.sdev0)
            st_numscalar("e(scale0)"  , S.scale0)
            st_numscalar("e(r2_p)"    , S.R2)
        }
        if (S.se) {
            st_numscalar("e(bwidth)", S.bwidth)
            st_global("e(bofinger)", (S.bofinger ? "bofinger" : ""))
            st_global("e(denmethod)", S.denmethod)
            if (S.denmethod=="kernel") {
                st_numscalar("e(kbwidth)", S.kbwidth)
                st_global("e(kernel)", S.kernel)
            }
            else {
                st_matrix("e(b_lo)", S.b_lo')
                st_matrixcolstripe("e(b_lo)", cstripe)
                st_matrix("e(b_up)", S.b_up')
                st_matrixcolstripe("e(b_up)", cstripe)
            }
            st_matrix("e(IFoffset)", S.IFoffset)
            st_matrixcolstripe("e(IFoffset)", cstripe)
        }
    }
    else if (S.cmd=="m") {
        st_global("e(title)", sprintf("M regression (%g%% efficiency)",
            round(S.eff,.1)))
        st_numscalar("e(k)", S.k)
        st_numscalar("e(efficiency)", S.eff)
        st_numscalar("e(iterations)", S.f.iter)
        st_numscalar("e(converged)", S.f.converged)
        st_matrix("e(b_init)", S.b_init')
        st_matrixcolstripe("e(b_init)", st_matrixcolstripe("e(b)"))
        if (S.r2) {
            st_matrix("e(b0)", S.b0)
            st_matrixcolstripe("e(b0)", ("", "_cons"))
            st_numscalar("e(scale0)"  , S.scale0)
            st_numscalar("e(r2_w)"    , S.R2[1])
            st_numscalar("e(r2_p)"    , S.R2[2])
        }
    }
    else if (S.cmd=="s") {
        st_global("e(title)", sprintf("S regression (%g%% efficiency)",
            round(S.eff,.1)))
        st_numscalar("e(k)", S.k)
        st_numscalar("e(bp)", S.bp)
        st_numscalar("e(efficiency)", S.eff)
        st_numscalar("e(delta)", S.delta)
        st_numscalar("e(nsamp)", S.nsamp)
        st_numscalar("e(nkeep)", S.nkeep)
        st_numscalar("e(rsteps)", S.rsteps)
        if (S.p1) {
            st_global("e(m)", invtokens(S.x1))
            st_numscalar("e(m_k)", S.k1)
            st_numscalar("e(m_efficiency)", S.eff1)
        }
        if (S.r2) {
            st_matrix("e(b0)", (S.b0, S.scale0))
            st_matrixcolstripe("e(b0)", ("S", "_cons") \ ("scale", "_cons"))
            st_numscalar("e(scale0)"  , S.scale0)
            st_numscalar("e(r2_w)"    , S.R2[1])
            st_numscalar("e(r2_p)"    , S.R2[2])
        }
        if (S.hm) {
            st_numscalar("e(hausman_"+(S.ftest ? "F" : "chi2")+")", S.hm_chi2)
            st_numscalar("e(hausman_p)", S.hm_p)
        }
    }
    else if (S.cmd=="mm") {
        st_global("e(title)", sprintf("MM regression (%g%% efficiency)",
            round(S.eff,.1)))
        st_numscalar("e(k)", S.k)
        st_numscalar("e(efficiency)", S.eff)
        st_numscalar("e(iterations)", S.f.iter)
        st_numscalar("e(converged)", S.f.converged)
        // carry forward settings of S estimator
        st_numscalar("e(kS)", S.kS)
        st_numscalar("e(effS)", S.effS)
        st_numscalar("e(bp)", S.bp)
        st_numscalar("e(delta)", S.delta)
        st_numscalar("e(nsamp)", S.nsamp)
        st_numscalar("e(nkeep)", S.nkeep)
        st_numscalar("e(rsteps)", S.rsteps)
        if (S.x1!="") {
            st_global("e(m)", S.x1)
            st_numscalar("e(m_k)", S.k1)
            st_numscalar("e(m_efficiency)", S.eff1)
        }
        if (S.r2) {
            st_matrix("e(b0)", (S.b0, S.b0S, S.scale0))
            st_matrixcolstripe("e(b0)", (("MM", "S", "scale")', J(3, 1, "_cons")))
            st_numscalar("e(scale0)"  , S.scale0)
            st_numscalar("e(r2_w)"    , S.R2[1])
            st_numscalar("e(r2_p)"    , S.R2[2])
        }
        if (S.hm) {
            st_numscalar("e(hausman_"+(S.ftest ? "F" : "chi2")+")", S.hm_chi2)
            st_numscalar("e(hausman_p)", S.hm_p)
        }
    }
    else { // lts/lqs/lms
        st_global("e(title)", strupper(S.cmd)+" regression")
        st_numscalar("e(s0)", S.s0)
        st_numscalar("e(h)", S.h)
        st_numscalar("e(q_h)", S.q_h)
        st_numscalar("e(crit)", S.c)
        st_numscalar("e(nsamp)", S.nsamp)
        if (S.cmd!="lms") st_numscalar("e(bp)",  S.bp)
        if (S.cmd=="lts") {
            st_numscalar("e(csteps)", S.csteps)
            st_numscalar("e(nkeep)", S.nkeep)
        }
        if (S.r2) {
            st_matrix("e(b0)", S.b0)
            st_matrixcolstripe("e(b0)", ("", "_cons"))
            st_numscalar("e(s0_0)"    , S.scale0)
            st_numscalar("e(r2_p)"    , S.R2)
        }
    }
}

void rr_post_modeltest(struct rr scalar S)
{
    real scalar t, pval, df_r
    
    if (S.p==0) { // constant-only model
        t    = 0
        pval = 1
    }
    else {
        t    = S.f.b[|1\S.p|]' * invsym(S.V[|1,1 \ S.p,S.p|]) * S.f.b[|1\S.p|]
        pval = chi2tail(S.p, t)
    }
    if (S.ftest) {
        t = t / S.p
        df_r = S.N_clust<. ? S.N_clust - 1 : S.df
        st_numscalar("e(F)", t)
        st_numscalar("e(p)", Ftail(S.p, df_r, t))
    }
    else {
        st_numscalar("e(chi2)", t)
        st_numscalar("e(p)", pval)
    }
}

// obtain linear prediction

real colvector rr_xb(real matrix X, real colvector b, real scalar cons)
{
    real scalar k
    if (cons) {
        k = cols(X)
        if (k==0) return(J(rows(X),1,b))
        return(X * b[|1\k|] :+ b[k+1])
    }
    return(X * b)
}

// obtain residual (and set scale to zero in case of "perfect" fit)

real colvector rr_resid(real colvector y, real matrix X, real colvector b,
    real scalar cons, | real scalar scale, real colvector xb)
{
    xb = rr_xb(X, b, cons)
    return(_rr_resid(y, xb, scale))
}

real colvector _rr_resid(real colvector y, real colvector xb,
    | real scalar scale)
{
    if (mreldif(xb, y)<1e-14) {     // "perfect" fit
        scale = 0                   // set scale to 0
        return(xb*0)                // set residuals to zero
    }
    return(y - xb)
}

// compute R-squared

void rr_r2(real colvector r, real colvector y, real colvector w,
    struct rr scalar S)
{
    // r2_w (cf. Heritier et al. 2009, p. 68)
    S.R2 = rr_r2_w(r, y, w:*S.f.W)
    
    // r2_rho based on constant-only fit (cf. Chen 2002, p.9)
    if  (S.f.scale==0) S.R2 = S.R2, 1
    else {
        if (S.cons & S.p==0) {
            S.b0 = S.f.b
            if (S.cmd!="mm") S.scale0 = S.f.scale
        }
        else if (S.cmd=="mm" | S.cmd=="m") {
            if (S.dots) rr_printf("{txt}fitting empty model ...")
            if      (S.cmd=="mm") rr_mm_empty(y, w, S)
            else if (S.cmd=="m")  rr_m_empty(y, w, S)
            else exit(error(3300)) // cannot be reached
            if (S.dots) rr_printf("{txt} done\n")
        }
        S.R2 = S.R2, rr_r2_rho(r, y, w, S)
    }
}

real scalar rr_r2_w(real colvector r, real colvector y, real colvector w)
{
    return(1 - editmissing(mean(r:^2, w)/mean((y :- mean(y, w)):^2, w), 0))
}

real scalar rr_r2_rho(real colvector r, real colvector y, real colvector w, 
    struct rr scalar S)
{
    real colvector rho, rho0
    
    if (S.obf=="biweight") rho = mm_biweight_rho(r/S.f.scale, S.k)
    else                   rho = mm_huber_rho(r/S.f.scale, S.k)
    if (S.obf=="biweight") rho0 = mm_biweight_rho((y :- S.b0)/S.f.scale, S.k)
    else                   rho0 = mm_huber_rho((y :- S.b0)/S.f.scale, S.k)
    return(1 - editmissing(mean(rho,w)/mean(rho0,w), 0))
}

// obtain inverse of X'X using mean deviation if there is a constant
// (numerically stable variant of invsym(quadcross(X,1,w,X,1)))
// note that w is assumed to be a vector here, i.e. not a scalar; scalar w
// needs to be specified as J(n,1,w)

real matrix rr_XXinv(real matrix X, real colvector w, real scalar cons)
{
    real colvector k
    real rowvector means
    real matrix    XXinv
    
    if (cons==0) return(invsym(quadcross(X, cons, w, X, cons)))
    k = cols(X)
    if (k==0) return(1/quadsum(w)) // w assumed non-scalar!!!
    means = mean(X, w)
    XXinv = invsym(quadcrossdev(X, means, w, X, means))
    XXinv = XXinv \ -(means * XXinv)
    XXinv = (XXinv, (XXinv[k+1,]' \ 1/quadsum(w) - means*XXinv[k+1,]'))
    return(XXinv)
}

// compute VCE from IFs

real matrix rr_VCE(real matrix IF, real colvector w, real scalar fw, 
    real scalar p, real scalar N, transmorphic colvector clust, 
    real scalar N_clust)
{
    real scalar c
    real matrix X
    
    // no clusters
    if (rows(clust)==0) {
        c = max((editmissing((N / (N-p)),0),0))
        if (w==1) return(makesymmetric(c * cross(IF, IF)))
        if (fw)   return(makesymmetric(c * cross(IF, w, IF)))
                  return(makesymmetric(c * cross(IF, w:^2, IF)))
    }
    X = _rr_VCE_csum(IF, w, clust)
    N_clust = rows(X)
    c = max((editmissing((N_clust/(N_clust - 1) * (N-1)/(N-p)),0),0))
        // omit (N-1)/(N-p) for results consistent with svy
    return(makesymmetric(c * cross(X, X)))
}

real matrix _rr_VCE_csum(real matrix X, real colvector w, 
     transmorphic colvector C) // aggregate X*w by clusters
{
    real scalar    i, a, b
    real colvector p, nc
    real matrix    S
    
    if (rows(w)!=1) p = mm_order(C, 1, 1) // stable sort
    else            p = order(C, 1)
    nc = select(1::rows(C), _mm_unique_tag(C[p])) // first obs in each cluster
    i  = rows(nc)
    S  = J(i, cols(X), .)
    a  = rows(C) + 1
    if (rows(w)==1) {
        for (;i;i--) {
            b = a - 1
            a = nc[i]
            S[i,.] = cross(w, X[p[|a\b|],.]) 
        }
    }
    else {
        for (;i;i--) {
            b = a - 1
            a = nc[i]
            S[i,.] = cross(w[p[|a\b|]], X[p[|a\b|],.])
        }
    }
    return(S)
}

// determine number of subsamples from alpha and eps

void rr_nsamp(real scalar p, real scalar min, real scalar max, struct rr scalar S)
{
    if (S.alpha>=.) S.alpha = 0.01
    if (S.eps>=.)   S.eps   = min((0.2, S.bp/100))
    S.nsamp = ceil(ln(S.alpha) / ln(1 - (1 - S.eps)^max((p,1))))
    if      (S.nsamp<min) S.nsamp = min
    else if (S.nsamp>max) S.nsamp = max
}

// print with displayflush

void rr_printf(string scalar s, | transmorphic scalar arg)
{
    if (args()<2) printf(s)
    else          printf(s, arg)
    displayflush()
}

// progress bar for subsampling algorithms

real scalar rr_progress_init(real scalar n)
{
    printf("{txt}enumerating {res}%g{txt} candidates ", n)
    if (n>=20) printf("0%%")
    displayflush()
    return(0)
}

void rr_progress(real scalar i, real scalar j, real scalar n)
{
    if (n<20) {
        rr_printf(".")
        j++
        return
    }
    if (floor(i/n*20)>j) {
        rr_printf(".")
        j++
        if (!mod(j,4)) rr_printf("%g%%",j*5)
    }
}

void rr_progress_done(real scalar n)
{
    if (n<20) printf(" done")
    printf("\n")
    displayflush()
}

/*---------------------------------------------------------------------------*/
// IRLS optimizer
/*---------------------------------------------------------------------------*/

struct _rr_irls {
    real scalar      N, p, cons, df, wsum
    real scalar      k, delta
    real scalar      center, update
    real scalar      qd, dev
    real scalar      maxiter, tol, relax, dots
    real scalar      siter, sconv
    real scalar      s_init   // starting value for scale
    real colvector   b_init   // starting values for coefficients
    pointer(function) scalar W, rho
    real scalar      ivar, N_g
    pointer scalar   ginfo, id
}

struct _rr_irls scalar rr_irls_init(struct rr scalar S, 
    | string scalar obf, real scalar ivar)
{
    struct _rr_irls scalar M
    
    if (args()<2) obf = S.obf
    if (args()<3) ivar = 0
    if (obf=="huber") {
        M.W   = &mm_huber_w()
        M.rho = &mm_huber_rho()
    }
    else if (obf=="biweight") {
        M.W   = &mm_biweight_w()
        M.rho = &mm_biweight_rho()
    }
    else exit(error(3300))
    M.N       = S.N
    M.p       = S.p
    M.cons    = S.cons
    M.df      = S.df
    M.wsum    = S.wsum
    M.k       = S.k
    M.delta   = S.delta
    M.center  = S.center
    M.update  = S.update
    M.qd      = S.qd
    M.dev     = S.dev
    M.maxiter = S.maxiter // set maxiter=1 and relax=1 to do only a single step
    M.tol     = S.tol
    M.relax   = S.relax
    M.dots    = S.dots
    M.siter   = 0  // M-scale iterations (requires biweight, delta, wsum)
    M.sconv   = 0  // sconv=1: convergence if change in scale < tol
    M.s_init  = S.s_init
    M.b_init  = S.b_init
    if (ivar) {
        M.ivar  = S.ivar
        M.N_g   = S.N_g
        M.id    = &S.id
        M.ginfo = &S.ginfo
    }
    else M.ivar = 0
    return(M)
}

struct rr_fit scalar rr_irls(real colvector y, real matrix X, real colvector w,
    struct _rr_irls scalar S, 
    | real colvector r) // provide starting values implicitly; will be replaced
{
    real scalar    s0
    real colvector b0
    struct rr_fit scalar f
    transmorphic   t
    
    if (S.dots) rr_printf("{txt}iterating RLS ")
    // - starting values
    if (args()<5) {
        f.b = b0 = length(S.b_init) ? S.b_init : J(cols(X)+S.cons,1,0)
        r = y - rr_xb(X, b0, S.cons)
    }
    else f.b = b0 = length(S.b_init) ? S.b_init : J(cols(X)+S.cons,1,.)
    f.scale = S.s_init
    _rr_irls_s(f.scale, r, w, S.siter, S)
    f.W = J(rows(r),1,0) // so that exists if maxiter=0; will be used by rr_r2()
    // - IRLS
    f.iter = f.converged = 0
    while (f.iter<S.maxiter) {
        f.iter = f.iter + 1
        if (f.scale==0) {
            f.b = b0 // note: loop will exit below since S.tol is satisfied
            f.W = J(rows(r),1,1)
        }
        else {
            f.W = (*S.W)(r/f.scale, S.k)
            if (S.ivar) {
                t = _mm_areg(*S.ginfo, y, X, w:*f.W, S.qd)
                f.b = mm_areg_b(t)
            }
            else {
                t = mm_ls(y, X, w:*f.W, S.cons, S.qd, S.dev)
                f.b = mm_ls_b(t)
            }
        }
        if (S.dots) rr_printf(".")
        if (mreldif(f.b,b0)<=S.tol) {
            f.converged = 1
            break
        }
        if (f.iter==S.maxiter) break
        b0 = f.b
        if (S.ivar) r = mm_areg_e(t)
        else        r = y - rr_xb(X, b0, S.cons)
        if (S.update) {
            if (S.siter) s0 = f.scale // optimize M-scale
            else         s0 = .       // update MADN
            _rr_irls_s(s0, r, w, S.siter, S)
            if (S.sconv) {
                if (reldif(ln(s0),ln(f.scale))<=S.tol) {
                    f.converged = 1
                    break
                }
            }
            f.scale = s0
        }
    }
    if (S.ivar) {
        if (length(t)) { // t will not be set if maxiter==0
            f.u = mm_areg_u(t)
        }
    }
    if (S.dots) rr_printf(" done\n")
    if (f.converged==0 & S.relax==0) exit(error(430))
    return(f)
}

// obtain scale

void _rr_irls_s(real scalar s, real colvector r, real colvector w, 
    real scalar siter, struct _rr_irls scalar S)
{
    real scalar iter, s0
    
    if (s>=.) s = rr_madn(r, w, S.center, S.N, S.df)
    iter = 0
    while (iter<siter) {
        if (s==0) return
        iter++
        s0 = s
        s  = s0 * editmissing(sqrt(
             quadsum(w :* mm_biweight_rho(r / s0, S.k))/S.wsum // = mean()
             * (S.N / (S.df * S.delta))), 0)
        if (reldif(ln(s),ln(s0))<=S.tol) {
            return
        }
    }
}

// compute MADN

real scalar rr_madn(real colvector y, real colvector w, 
    real scalar center, real scalar N, real scalar df)
{
    real scalar p
    
    p = (2*N - df) / (2*N) // = (N + k + cons!=0) / (2*N)
    return(mm_quantile(abs(center ? y :- mm_median(y,w) : y), w, p)
        / invnormal(0.75))
}

/*---------------------------------------------------------------------------*/
// median regression
/*---------------------------------------------------------------------------*/

real colvector rr_lad(real colvector y, real matrix X, real colvector w, 
    real scalar cons, real scalar qd, real scalar demean)
{
    class mm_qr scalar S
    
    S.p(.5)
    S.qd(qd)
    S.demean(demean)
    S.data(y, X, w, cons)
    return(S.b())
}

/*---------------------------------------------------------------------------*/
// compute group mean or medians
/*---------------------------------------------------------------------------*/

real matrix rr_demean(struct mm_areg_struct_g scalar g, real matrix X,
    real colvector w)
{
    real matrix M
    
    M = X
    _mm_areg_gmean(g, M, w)
    return(X - M)
}

real matrix rr_demedian(struct mm_areg_struct_g scalar g, real matrix X,
    real colvector w)
{
    real matrix M
    
    M = X
    _rr_gmedian(g, M, w)
    return(X - M)
}

void _rr_gmedian(struct mm_areg_struct_g scalar g, real matrix X,
    real colvector w)
{
    if (g.sort) {
        _collate(X, g.p)
        __rr_gmedian(X, rows(w)==1 ? w : w[g.p], g.idx)
        _collate(X, invorder(g.p))
    }
    else __rr_gmedian(X, w, g.idx)
}

void __rr_gmedian(real matrix X, real colvector w, real colvector idx)
{
    real scalar    i, n, a, b, k
    real colvector ww
    real matrix    ab

    if (rows(X)<1) return
    n = rows(idx)
    b = 0
    if (rows(w)==1) {
        for (i=1; i<=n; i++) {
            a = b + 1
            b = idx[i]
            k = b - a
            if (!k) continue // no averaging necessary if less than two obs
            k++
            ab = (a,1 \ b,.)
            X[|ab|] = J(k, 1, mm_median(X[|ab|]))
        }
        return
    }
    for (i=1; i<=n; i++) {
        a = b + 1
        b = idx[i]
        k = b - a
        if (!k) continue // no averaging necessary if less than two obs
        k++
        ab = (a,1 \ b,.)
        ww = w[|ab|]
        if (quadsum(ww)) X[|ab|] = J(k, 1, mm_median(X[|ab|], ww))
        else             X[|ab|] = J(k, 1, mm_median(X[|ab|]))
            // using unweighted median if sum of weights is 0
    }
}

/*---------------------------------------------------------------------------*/
// nonsingular subsampler
/*---------------------------------------------------------------------------*/

// standardize data and destandardize results
// - with constant:    X = (X - MED) / MADN
// - without constant: X = X / MADN
// - skip rescaling if MADN=0

struct rr_std_struct {
    real scalar      p, cons, nostd
    real scalar      ymed, ymadn
    real rowvector   Xmed, Xmadn
}

struct rr_std_struct scalar rr_std(real colvector y, real matrix X,
    real colvector w, real scalar cons, real scalar nostd)
{
    struct rr_std_struct scalar S
    
    S.cons = cons
    S.p = cols(X)
    S.nostd = nostd
    if (S.nostd) {
        S.ymed = 0
        S.ymadn = 1
        return(S)
    }
    // y
    S.ymed = mm_median(y, w)
    if (S.cons) {
        y = y :- S.ymed
        S.ymadn = mm_median(abs(y), w)
    }
    else {
        S.ymadn = mm_median(abs(y :- S.ymed), w)
        S.ymed  = 0
    }
    S.ymadn = editvalue(S.ymadn / invnormal(0.75), 0, 1)
    y = y / S.ymadn
    if (S.p==0) return(S)
    // X
    S.Xmed = mm_median(X, w)
    if (S.cons) {
        X = X :- S.Xmed
        S.Xmadn = mm_median(abs(X), w)
    }
    else {
        S.Xmadn = mm_median(abs(X :- S.Xmed), w)
        S.Xmed  = J(1, S.p, 0)
    }
    S.Xmadn = editvalue(S.Xmadn / invnormal(0.75), 0, 1)
    X = X :/ S.Xmadn
    return(S)
}

void rr_destd(real colvector b, struct rr_std_struct scalar S)
{
    if (S.nostd) return
    if (S.cons) {
        b[S.p+1] = S.ymed + S.ymadn * b[S.p+1]
        if (!S.p) return
        b[|1\S.p|] = S.ymadn :/ S.Xmadn' :* b[|1\S.p|]
        b[S.p+1]   = b[S.p+1] - S.Xmed * b[|1\S.p|]
        return
    }
    b = S.ymadn :/ S.Xmadn' :* b
}

// obtain candidate fit from nonsingular subsample

struct rr_smpl_struct {
    real scalar      n, p, cons
    pointer scalar   y, X
    real colvector   I, i
    pointer(function) scalar f
}

struct rr_smpl_struct scalar rr_smpl_init(real colvector y, 
    real matrix X, real scalar p, real scalar cons, real scalar smpl)
{
    struct rr_smpl_struct scalar S
    
    if (smpl==1)      S.f = &_rr_smpl_naive()
    else if (smpl==2) S.f = &_rr_smpl_alt()
    else              S.f = &_rr_smpl_nonsing()
    S.cons = cons
    S.p = p + S.cons
    S.y = &y
    S.X = &X
    S.n = rows(y)
    if (smpl!=1) S.I = 1::S.n
    // could also restrict the sample to unique (y,X), but this does not seem 
    // worth the effort; last two lines would need to be replaced by the
    // following (would also need to adjust _rr_s_cand_naive() to
    // make use of S.I):
    //    S.I = select(1::rows(y), mm_uniqrows_tag((y, X)))
    //    S.n = rows(S.I)
    return(S)
}

real colvector rr_smpl(struct rr_smpl_struct scalar S) return((*S.f)(S))

real colvector rr_smpl_i(struct rr_smpl_struct scalar S) return(S.i)

real colvector _rr_smpl_naive(struct rr_smpl_struct scalar S)
{
    real scalar    i
    real matrix    X, XX
    
    for (i=1; i<=10000; i++) {
        if (S.p^2 < S.n/2) S.i = /*S.I[*/_mm_srswor_a(S.p, S.n)/*]*/
        else               S.i = /*S.I[*/_mm_srswor_b(S.p, S.n)/*]*/
        X = (*S.X)[S.i,]
        XX = /*quad*/cross(X,S.cons, X,S.cons)
        if (diag0cnt(invsym(XX))) continue // singular
        return(lusolve(XX, /*quad*/cross(X,S.cons, (*S.y)[S.i],0)))
    }
    _error(3498, "could not find non-singular subsample within 10'000 trials")
}

real colvector _rr_smpl_nonsing(struct rr_smpl_struct scalar S)
{
    // Modified Gaxpy LU decomposition to compute a trial estimate from a 
    // random non-singular subsample as proposed by:
    //    Koller, Manuel. 2012. Nonsingular subsampling for S-estimators with 
    //    categorical predictors. ETH Zurich. http://arxiv.org/abs/1208.5595v1
    // The algorithm by Koller uses jumbled observations; instead we use the 
    // Fisher–Yates shuffle; this is faster and conserves memory
    real scalar    j, k, q, m, mu, t, tol
    real colvector p, v, b
    real matrix    L, U
    real rowvector Ak, cons

    // Initialize variables, pivoting table p, selected subsample index vector s
    tol = 1e-7
    m = S.p; cons = J(S.cons, 1, 1)
    L = I(m); U = J(m, m, 0); S.i = p = 1::m; q = S.n
    // Find non-singular subsample and calculate LU decomposition
    for (j=1; j<=m; j++) {
        // Fisher–Yates shuffle
        t = ceil(uniform(1,1)*q); k = S.I[t]; S.I[t] = S.I[q]; S.I[q] = k; q--
        // Obtain data from selected observation
        Ak = ((*S.X)[k,]' \ cons)[p]
        // Koller's algorithm
        if (j==1) v = Ak
        else {  // (Forward)solve to get required column of U
            U[|1,j \ j-1,j|] = solvelower(L[|1,1 \ j-1,j-1|], Ak[|1 \ j-1|])
            v[|j \ m|] = Ak[|j \ m|] - L[|j,1 \ m,j-1|] * U[|1,j \ j-1,j|]
        }
        if (j<m) {
            // Find pivot
            mu = rr_maxindex(abs(v[|j \ m|])) + j - 1
            if (abs(v[mu])>=tol) {
                if (q==0) break //_error(3498, "could not find non-singular subsample")
                // Subsample is still non-singular
                S.i[j] = k
                // Swap variables
                p[j\mu] = p[mu\j]; v[j\mu] = v[mu\j]
                // Update L
                L[|j+1,j \ m,j|] = v[|j+1 \ m|] / v[j]
                // Swap rows of L
                if (j>1) rr_rswap(L, (j,1 \ j,j-1), (mu,1 \ mu,j-1))
            }
        }
        else if (abs(v[j])>=tol) S.i[j] = k
        if (abs(v[j])<tol) {
            if (q==0) _error(3498, "could not find non-singular subsample")
            // Singularity detected: skip this obs and try again if possible
            j--
            continue
        }
        U[j, j] = v[j]
    }
    // Solve and undo pivoting
    b = solvelower(U', (*S.y)[S.i])
    b = solveupper(L', b)
    b[p] = b
    return(b)
}

real colvector _rr_smpl_alt(struct rr_smpl_struct scalar S)
{
    // alternative nonsingular subsampler that works by expanding the subsample
    // (rather than exchanging observations)
    real scalar    i, j, n, p, q, cons
    real matrix    x, xx
    
    // Step 1: get p-subset; return solution if nonsingular
    cons = S.cons
    p = S.p
    n = q = S.n
    for (i=1; i<=p; i++) {
        j = ceil(uniform(1,1)*q)
        S.I[j\q] = S.I[q\j]
        q--
    }
    S.i = S.I[|q+1 \ n|]
    x = (*S.X)[S.i,]
    xx = /*quad*/cross(x,cons, x,cons)
    if (!diag0cnt(invsym(xx))) {
        return(lusolve(xx, /*quad*/cross(x,cons, (*S.y)[S.i],0)))
    }
    // Step 2: expand subset until nonsingular
    xx = xx / p // rescale: total -> mean
    while (q) {
        j = ceil(uniform(1,1)*q)
        x = (*S.X)[S.I[j],], J(1, cons, 1)
        S.I[j\q] = S.I[q\j]
        q--
        xx = xx + (x'x - xx)/(n-q) // mean updating
        if (diag0cnt(invsym(xx))) continue
        S.i = S.I[|q+1 \ n|]
        x = (*S.X)[S.i,]
        xx = /*quad*/cross(x,cons, x,cons)
        return(lusolve(xx, /*quad*/cross(x,cons, (*S.y)[S.i],0)))
    }
    _error(3498, "could not find non-singular subsample")
}

// swap slices within a matrix

void rr_rswap(real matrix X, real matrix a, real matrix b)
{
    real matrix hold
    
    hold = X[|a|]; X[|a|] = X[|b|]; X[|b|] = hold
}

// get index of (first) maximum in vector

real scalar rr_maxindex(real vector v)
{
    real colvector i
    real matrix    w
    pragma unset i
    pragma unset w
    
    maxindex(v, 1, i, w)    // ignores missing values!
    return(i[1])
}

/*---------------------------------------------------------------------------*/
// robreg ls
/*---------------------------------------------------------------------------*/

void rr_ls()
{
    real colvector   y, w, r
    real matrix      X
    transmorphic     t
    pointer scalar   Xd
    struct rr scalar S
    
    // setup
    S = rr_setup(y=., X=., w=.)

    // estimation
    if (S.ivar) {
        t = _mm_areg(S.ginfo, y, X, w, S.qd)
        S.f.b = mm_areg_b(t)
        if (S.se) S.Ginv = mm_areg_XXinv(t)
        if (S.usave) S.f.u = mm_areg_u(t)
        r = _rr_resid(y, mm_areg_xbu(t))
        S.corr = corr(variance((mm_areg_u(t), mm_areg_xb(t)), w))[2,1]
        S.f.scale = mean(r:^2, w)
        if (S.r2) {
            S.b0 = mm_areg_ymean(t)
            S.scale0 = mean((y :- S.b0):^2, w)
        }
        if (S.vce) {
            Xd = &mm_areg_Xd(t)
            *Xd = *Xd :+ mm_areg_means(t) // this modifies t.Xd
        }
        else Xd = &J(0,0,.)
        rr_update_omit(X, S, mm_areg_k_omit(t), mm_areg_omit(t), *Xd)
    }
    else {
        t = mm_ls(y, X, w, S.cons, S.qd, S.dev)
        S.f.b = mm_ls_b(t)
        if (S.se) S.Ginv = mm_ls_XXinv(t)
        r = rr_resid(y, X, S.f.b, S.cons, S.f.scale) // sets scale=0 if perfect fit
        S.f.scale = mean(r:^2, w)
        if (S.r2) {
            if (S.cons & S.p==0) { // main model is constant-only model
                S.b0 = S.f.b
                S.scale0 = S.f.scale
            }
            else {
                S.b0 = mm_ls_ymean(t)
                S.scale0 = mean((y :- S.b0):^2, w)
            }
        }
    }
    if (S.r2) {
        S.R2 = 1 - editmissing(S.f.scale/S.scale0, 0)
        S.scale0 = sqrt(S.scale0 * editmissing((S.N / (S.N-1)), 0))
    }
    S.f.scale = sqrt(S.f.scale * editmissing(S.N / S.df, 0))
    if (S.vce) rr_ls_V(r, S.ivar ? *Xd : X, w, S)
    if (S.se)  S.Ginv = S.Ginv * S.f.scale^2
    
    // post results
    rr_isrtomitted(S)
    rr_post(S)
}

void rr_ls_scores()
{
    stata("qui replace \`varlist' = (\`e(depvar)' - \`varlist') " +
        "/ \`e(scale)'^2 if \`touse'")
}

void rr_ls_V(real colvector r, real matrix X, real colvector w,
    struct rr scalar S)
{
    real scalar p
    real matrix IF
    
    IF = (r :* (X, J(rows(X), S.cons, 1))) * S.Ginv'
    if      (S.ivar==1) p = S.p + S.cons // ivar() (df like xtreg,fe)
    else if (S.ivar==2) p = S.p + S.N_g  // absorb() (df like areg)
    else                p = S.p + S.cons // else
    S.V = rr_VCE(IF, w, S.fw, p, S.N, S.clust, S.N_clust)
}

/*---------------------------------------------------------------------------*/
// robreg q
/*---------------------------------------------------------------------------*/

void rr_q_scores()
{
    real scalar    q
    real colvector y, xb
    
    q  = st_numscalar("e(q)")
    y  = st_data(., st_global("e(depvar)"), st_local("touse"))
    xb = st_data(., st_local("varlist"), st_local("touse"))
    st_store(., st_local("varlist"), st_local("touse"), (q :- (y :<= xb)))
}

void rr_q()
{
    real colvector     y, w, r
    real matrix        X
    struct rr scalar   S
    class mm_qr scalar Q
    
    // setup
    S   = rr_setup(y=., X=., w=.)
    S.q = strtoreal(st_local("quantile"))
    S.denmethod = (st_local("fitted")!="" ? "fitted" : "kernel")
    S.bofinger = (st_local("bofinger")!="")
    S.kernel = "gaussian"
    Q.p(S.q)
    Q.qd(S.qd)
    Q.demean(S.dev)
    Q.collin(0)  // collinear terms already eliminated
    Q.tol(S.tol)
    Q.maxiter(S.maxiter)
    Q.log(S.dots*3)
    Q.data(y, X, w, S.cons)
    
    // starting values
    if (S.init!="") {
        S.b_init = J(S.p + S.cons, 1, 0)
        rr_m_copy_b_init(S.b_init, S.xvars, S.cons, S.init)
        Q.b_init(S.b_init)
    }
    
    // estimation
    if (S.dots) rr_printf("{txt}iterating Frisch-Newton algorithm ")
    S.f.b         = Q.b()
    S.b_init      = Q.b_init()
    if (S.dots) rr_printf("{txt} done\n")
    S.f.iter      = Q.iter()
    S.f.converged = Q.converged()
    if (S.f.converged==0 & S.relax==0) exit(error(430))
    S.wsum = Q.N() // will be used by rr_q_V()
    r = rr_resid(y, X, S.f.b, S.cons, S.f.scale) // sets scale=0 if perfect fit
    if (S.f.scale!=0) {
        S.sdev = Q.sdev()
        S.f.scale = rr_madn(r, w, S.center, S.N, S.df)
    }
    else S.sdev = 0
    if (S.r2) rr_q_r2(y, w, S)
    if (S.se) rr_q_V(r, y, X, w, S)
    
    // post results
    rr_isrtomitted(S)
    rr_post(S)
}

void rr_q_r2(real colvector y, real colvector w, struct rr scalar S)
{
    real colvector r
    class mm_qr scalar Q
    
    if (S.cons & S.p==0) {
        S.b0 = S.f.b
        S.sdev0 = S.sdev
        S.scale0 = S.f.scale
    }
    else {
        if (S.dots) rr_printf("{txt}fitting empty model ...")
        Q.p(S.q)
        Q.qd(S.qd)
        Q.demean(S.dev)
        Q.tol(S.tol)
        Q.maxiter(S.maxiter)
        Q.data(y, ., w, 1)
        S.b0 = Q.b()
        if (Q.converged()==0 & S.relax==0) exit(error(430))
        r = _rr_resid(y, J(rows(y),1,S.b0), S.scale0)
        if (S.f.scale!=0) {
            S.sdev0 = Q.sdev()
            S.scale0 = rr_madn(r, w, S.center, S.N, S.N-1)
        }
        else S.sdev0 = 0
        if (S.dots) rr_printf("{txt} done\n")
    }
    S.R2 = 1 - editmissing(S.sdev/S.sdev0, 0)
}

void rr_q_V(real colvector r, real colvector y, real matrix X, real colvector w,
    struct rr scalar S)
{
    real scalar    sigma, iqrn
    real colvector z
    real matrix    IF
    class mm_qr scalar Q
    
    if (S.dots) rr_printf("{txt}computing standard errors ...")
    // determine bandwidth
    if (S.bofinger) {
        S.bwidth = S.N^-.2 * ((4.5*normalden(invnormal(S.q))^4) / 
            (2*invnormal(S.q)^2+1)^2)^.2
    }
    else {
        S.bwidth = S.N^(-1/3) * invnormal(.5 + S.cilevel/200)^(2/3) * 
            ((1.5*normalden(invnormal(S.q))^2) / (2*invnormal(S.q)^2+1))^(1/3)
    }
    if (S.bwidth<. & S.q<1 & S.q>0) {
        // make sure that tau +/- h is within (0,1)
        while ((S.q-S.bwidth)<=0 | (S.q+S.bwidth)>=1) S.bwidth = S.bwidth/2
    }
    // density estimation
    if (S.denmethod=="kernel") {
        sigma     = sqrt(variance(r, w)*((S.wsum-1) / S.df))
        iqrn      = mm_iqrange(r, w) / (invnormal(0.75) - invnormal(0.25))
        S.kbwidth = min((sigma, iqrn)) * 
            (invnormal(S.q+S.bwidth) - invnormal(S.q-S.bwidth))
        z = editmissing(mm_kern_gaussian(r/S.kbwidth) / S.kbwidth, 0)
    }
    else {
        Q.qd(S.qd)
        Q.demean(S.dev)
        Q.collin(0)  // collinear terms already eliminated
        Q.tol(S.tol)
        Q.maxiter(S.maxiter)
        Q.log(0)
        Q.data(y, X, w, S.cons)
        Q.b_init(S.f.b) // use main fit for starting values
        Q.p(S.q - S.bwidth)
        S.b_lo = Q.b()
        if (Q.converged()==0 & S.relax==0) exit(error(430))
        Q.p(S.q + S.bwidth)
        S.b_up = Q.b()
        if (Q.converged()==0 & S.relax==0) exit(error(430))
        z = rr_xb(X, S.b_up-S.b_lo, S.cons)
        z = z :* (z:>0) // reset negative values to 0
        z = editmissing((2*S.bwidth) :/ z, 0)
    }
    // compute VCE
    S.Ginv = rr_XXinv(X, z:*w, S.cons)
    z = (r :<= 0)
    IF = ((S.q :- z) :* (X, J(rows(X), S.cons, 1))) * S.Ginv'
    S.IFoffset = mean(IF, w) // mean(IF)=0 only holds approximately for qr
    if (S.vce) {
        IF = IF :- S.IFoffset
        S.V = rr_VCE(IF, w, S.fw, S.p+S.cons, S.N, S.clust, S.N_clust)
    }
    if (S.dots) rr_printf("{txt} done\n")
}

/*---------------------------------------------------------------------------*/
// robreg m
/*---------------------------------------------------------------------------*/

void rr_m_scores()
{
    real scalar    k
    string scalar  obf
    real colvector psi
    
    obf = st_global("e(obf)")
    k   = st_numscalar("e(k)")
    psi = (st_data(., st_global("e(depvar)"), st_local("touse"))
          - st_data(., st_local("varlist"), st_local("touse"))) /
          st_numscalar("e(scale)")
    if (obf=="biweight") psi = mm_biweight_psi(psi, k)
    else                 psi = mm_huber_psi(psi, k)
    st_store(., st_local("varlist"), st_local("touse"), psi)
}

void rr_m()
{
    real colvector   y, w, r, xb, u0
    real matrix      X
    struct rr scalar S
    transmorphic     t
    pragma unset xb
    
    // setup
    S = rr_setup(y=., X=., w=.)
    
    // tuning constant
    if (S.obf=="biweight") {
        if (S.k>=.) S.k   = mm_biweight_k(S.eff)
        else        S.eff = mm_biweight_eff(S.k) * 100
    }
    else {
        if (S.k>=.) S.k   = mm_huber_k(S.eff)
        else        S.eff = mm_huber_eff(S.k) * 100
    }
    
    // starting values
    S.s_init = strtoreal(st_local("scale"))
    if (S.init=="ls") {
        if (S.ivar) {
            if (S.dots) rr_printf("{txt}obtaining LS starting values ...")
            t = _mm_areg(S.ginfo, y, X, w, S.qd)
            S.b_init = mm_areg_b(t)
            u0 = mm_areg_u(t)
            r = mm_areg_e(t)
            if (S.dots) rr_printf("{txt} done\n")
            rr_update_omit(X, S, mm_areg_k_omit(t), mm_areg_omit(t))
        }
        else {
            if (S.dots) rr_printf("{txt}obtaining LS starting values ...")
            S.b_init = mm_ls_b(mm_ls(y, X, w, S.cons, S.qd, S.dev))
            r = y - rr_xb(X, S.b_init, S.cons)
            if (S.dots) rr_printf("{txt} done\n")
        }
    }
    else if (S.init=="lad") {
        if (S.ivar) {
            if (S.dots) rr_printf("{txt}obtaining LAD starting values ...")
            t = _mm_aqreg(S.ginfo, y, X, w, 0.5, S.qd)
            S.b_init = mm_aqreg_b(t)
            u0 = mm_aqreg_u(t)
            r = mm_aqreg_e(t)
            if (S.dots) rr_printf("{txt} done\n")
            rr_update_omit(X, S, mm_aqreg_k_omit(t), mm_aqreg_omit(t))
        }
        else {
            if (S.dots) rr_printf("{txt}obtaining LAD starting values ...")
            S.b_init = rr_lad(y, X, w, S.cons, S.qd, S.dev)
            r = y - rr_xb(X, S.b_init, S.cons)
            if (S.dots) rr_printf("{txt} done\n")
        }
    }
    else {
        // note: not reached if ivar() or absorb()
        S.b_init = J(S.p + S.cons, 1, 0)
        rr_m_copy_b_init(S.b_init, S.xvars, S.cons, S.init)
        r = y - rr_xb(X, S.b_init, S.cons)
    }
    
    // estimation
    S.f = rr_irls(y, X, w, rr_irls_init(S, S.obf, S.ivar), r)
    if (S.ivar) {
        if (!length(S.f.u)) S.f.u = u0 // can happen e.g. if S.maxiter=0
        xb = rr_xb(X, S.f.b, S.cons)
        r = _rr_resid(y, xb + S.f.u, S.f.scale)
        S.corr = corr(variance((S.f.u,xb), w))[2,1]
    }
    else r = rr_resid(y, X, S.f.b, S.cons, S.f.scale)
    if (S.r2) rr_r2(r, y, w, S)
    if (S.se) rr_m_V(r, X, w, S)
    
    // post results
    rr_isrtomitted(S)
    rr_post(S)
}

void rr_m_copy_b_init(real colvector b, string rowvector xvars, 
    real scalar cons, string scalar m)
{
    real scalar      i, r
    real matrix      b0
    string rowvector coefs0, coefs
    
    if (cons) coefs = xvars, "_cons"
    else      coefs = xvars
    b0 = st_matrix(m)
    coefs0 = st_matrixcolstripe(m)[,2]' // (ignoring equations)
    i = length(coefs0); r = length(coefs)
    for (;i;i--) {
        if (anyof(coefs, coefs0[i])) {
            b[select(1..r, coefs:==coefs0[i])[1]] = b0[1,i]
        }
    }
}

void rr_m_V(real colvector r, real matrix X0, real colvector w,
    struct rr scalar S)
{
    real scalar    p
    real colvector z, wphi, psi
    real matrix    IF
    pointer scalar X
    
    if (S.dots) rr_printf("{txt}computing standard errors ...")
    z = r / S.f.scale
    if (S.obf=="biweight") wphi = w :* mm_biweight_phi(z, S.k)
    else                   wphi = w :* mm_huber_phi(z, S.k)
    if (S.ivar & S.p) X = &(rr_demean(S.ginfo,X0,wphi) :+ mean(X0,wphi))
    else              X = &X0
    S.Ginv = rr_XXinv(*X, wphi, S.cons) * S.f.scale
    if (S.vce) {
        if (S.obf=="biweight") psi = mm_biweight_psi(z, S.k)
        else                   psi = mm_huber_psi(z, S.k)
        if      (S.ivar==1) p = S.p + S.cons // ivar() (df like xtreg,fe)
        else if (S.ivar==2) p = S.p + S.N_g  // absorb() (df like areg)
        else                p = S.p + S.cons // else
        IF = psi :* (*X, J(rows(*X), S.cons, 1)) * S.Ginv'
        S.V = rr_VCE(IF, w, S.fw, p, S.N, S.clust, S.N_clust)
    }
    if (S.dots) rr_printf("{txt} done\n")
}

void rr_m_empty(real colvector y, real colvector w, struct rr scalar S)
{   // constant-only fit using median or mean of Y as starting value, depending
    // on init() option; median will be used if custom starting values have been
    // specified in init(); MADN will be used as (starting value) for the scale
    struct rr_fit scalar  f
    struct _rr_irls scalar S0
    
    S0 = rr_irls_init(S)
    S0.s_init = .
    S0.b_init = (S.init=="ls" ? mean(y,w) : mm_median(y,w))
    S0.cons = 1
    S0.p = 0
    S0.df = S0.N-1
    S0.dots = 0
    f = rr_irls(y, J(rows(y), 0, .), w, S0)
    S.b0     = f.b
    S.scale0 = f.scale
}

/*---------------------------------------------------------------------------*/
// robreg s
/*---------------------------------------------------------------------------*/

void rr_s_scores()
{
    real scalar      k, c
    real colvector   e
    string rowvector v
    
    v = tokens(st_local("varlist"))
    k = st_numscalar("e(k)")
    e = (st_data(., st_global("e(depvar)"), st_local("touse"))
        - st_data(., v[1], st_local("touse"))) / st_numscalar("e(scale)")
    st_store(., v[1], st_local("touse"), mm_biweight_psi(e, k))
    if (length(v)==1) return
    if      (st_global("e(ivar)")!="")   c = st_numscalar("e(N_g)")
    else if (st_global("e(absorb)")!="") c = st_numscalar("e(N_g)")
    else                                 c = st_global("e(noconstant)")==""
    c = st_numscalar("e(df_m)") + c
    c = st_numscalar("e(N)") / (st_numscalar("e(N)") - c)
    st_store(., v[2], st_local("touse"), c * mm_biweight_rho(e, k) :- 
        st_numscalar("e(delta)"))
}

void rr_s()
{
    real colvector   y, y1, w, r, xb
    real matrix      X, X1
    pointer scalar   y2, X2
    struct rr scalar S
    struct rr_std_struct scalar std
    pragma unset xb
    
    // S setup
    S = rr_setup(y=., X=., w=.)
    S.obf = "biweight"
    S.wsum = (rows(w)==1 ? rows(y)*1 : quadsum(w))
    
    // tuning constant
    if (S.k>=.) S.k  = mm_biweight_k_bp(S.bp)
    else        S.bp = mm_biweight_bp(S.k) * 100
    S.eff   = mm_biweight_eff(S.k) * 100
    S.delta = S.bp/100 * S.k^2/6
    
    // data preparation
    if (S.dots) rr_printf("{txt}preparing data for subsampling ... ")
    y1 = y; y2 = &y1
    X1 = X; X2 = &X1
    // - standardize data (to increase numerical stability)
    std = rr_std(y1, X1, w, S.cons, S.nostd)
    // - de-median data if ivar()/absorb()
    if (S.ivar) {
        y2 = &rr_demedian(S.ginfo, *y2, w)
        X2 = &rr_demedian(S.ginfo, *X2, w)
        rr_s_update_omit(*X2, w, S, X, X1, std)
    }
    // - M-S setup
    S.p1 = 0; S.p2 = S.p; S.cons2 = S.cons
    S.x1 = tokens(st_local("m_vars"))
    _rr_ms_match_x1(S)
    if (S.p1) { // residualize y and X for S part (using LAD starting values)
        S.k1   = strtoreal(st_local("m_k"))
        S.eff1 = strtoreal(st_local("m_efficiency"))
        if (S.k1>=.) S.k1   = mm_huber_k(S.eff1)
        else         S.eff1 = mm_huber_eff(S.k1) * 100
        _rr_s_mresid(y2, X2, w, S)
    }
    // - number of subsamples
    if (S.nsamp>=.)      rr_nsamp(S.p2, 20, 1000, S)
    if (S.nkeep>S.nsamp) S.nkeep = S.nsamp
    if (S.dots) rr_printf("{txt}done\n")
    
    // estimation
    S.f = _rr_s(y1, X1, *y2, *X2, w, S, std)
    y1 = J(0,1,.); X1 = J(0,0,.); y2 = X2 = NULL // release memory
    if (S.ivar) {
        xb = rr_xb(X, S.f.b, S.cons)
        r = _rr_resid(y, xb + S.f.u, S.f.scale)
        S.corr = corr(variance((S.f.u,xb), w))[2,1]
    }
    else r = rr_resid(y, X, S.f.b, S.cons, S.f.scale)
    if (S.r2) rr_r2(r, y, w, S)
    if (S.se) rr_s_V(r, y, X, w, S)
    
    // post results
    rr_isrtomitted(S)
    rr_post(S)
}

// - look for collinear terms in de-medianed data
void rr_s_update_omit(real matrix X, real colvector w, struct rr scalar S, 
    real matrix X0, real matrix X1, struct rr_std_struct scalar std)
{
    real scalar    k_omit
    real colvector omit
    real rowvector p
    real matrix    XX
    
    // remove omitted terms
    if (!S.p) return
    XX = S.qd ? quadcross(X,1, w, X,1) : cross(X,1, w, X,1) // include constant
    omit = diagonal(invsym(XX, S.p+1))[|1\S.p|]:==0     // do not omit constant
    k_omit = sum(omit)
    if (!k_omit) return
    if (S.dots) rr_printf("\n")
    rr_update_omit(X, S, sum(omit), omit, X0, X1)
    
    // update std
    if (std.nostd) return
    p = select(1::rows(omit), !omit)'
    if (length(p)==0) p = J(1,0,.)
    std.Xmed  = std.Xmed[p]
    std.Xmadn = std.Xmadn[p]
    std.p     = length(std.Xmed)
}

// - separate terms between S and M part of model
void _rr_ms_match_x1(struct rr scalar S)
{
    real colvector d
    
    if (length(S.x1)==0) return
    if (S.p==0) return
    // - tag variables in xvars that are also in x1; xvars assumed unique
    d = !mm_unique_tag((S.xvars,S.x1), 2)[|1\S.p|] 
    // - select variables
    if (any(d)==0) { // no matching variables
        S.x1 = J(1,0,"")
        return
    }
    S.x1id  = select(1..S.p, d)
    S.p1    = cols(S.x1id)
    S.x1    = S.xvars[S.x1id]
    if (all(d)) S.x2id = J(1,0,.)
    else        S.x2id = select(1..S.p, d:==0)
    S.p2    = cols(S.x2id)
    S.cons2 = 1 // always include constant in S part
}

// - residualize variables of S part of model
void _rr_s_mresid(pointer scalar y2, pointer scalar X2, real colvector w,
    struct rr scalar S)
{
    real scalar    j
    real colvector y
    real matrix    X, X1
    struct _rr_irls scalar M
    pragma unset   X1
    
    y = *y2
    st_subview(X1, *X2, ., S.x1id)
    X = (*X2)[,S.x2id]
    M = rr_irls_init(S, "huber"); M.dots = M.qd = M.dev = 0; M.k = S.k1
    for (j=S.p2; j; j--) __rr_s_mresid(X[,j], X1, w, M)
    __rr_s_mresid(y, X1, w, M)
    y2 = &y
    X2 = &X
}

void __rr_s_mresid(real colvector y, real matrix X,
    real colvector w, struct _rr_irls scalar S)
{
    struct rr_fit scalar f
    
    S.b_init = rr_lad(y, X, w, S.cons, S.qd, S.dev)
    S.s_init = .
    f = rr_irls(y, X, w, S)
    y = y - rr_xb(X, f.b, S.cons)
}

// - subsampling algorithm
struct rr_fit scalar _rr_s(real colvector y, real matrix X, 
    real colvector y2, real matrix X2, real colvector w,
    struct rr scalar S, struct rr_std_struct scalar std)
{
    real scalar       i, j, j0, doti, null
    real colvector    b, r, s, s0, B0, x0
    pointer colvector B, U
    transmorphic      t
    struct rr_fit scalar f
    struct _rr_irls scalar M, M0
    
    // whether to include estimation of empty model
    null = (S.r2 & (S.p | S.cons))
    
    // enumerate candidates
    if (S.dots) doti = rr_progress_init(S.nsamp)
    M = rr_irls_init(S, S.obf, S.ivar)
    M.dots = M.qd = M.dev = 0; M.cons = S.cons
    M.maxiter = S.rsteps; M.relax = 1      // number of refinement steps
    M.siter = 1; M.update = 1; M.sconv = 1 // do one scale step per rstep
    t = rr_smpl_init(y2, X2, S.p2, S.cons2, S.smpl)
    B = J(S.nkeep, 1, NULL)
    if (S.ivar) U = J(S.nkeep, 1, NULL)
    s = J(S.nkeep, 1, .)
    if (null) {
        B0 = s0 = s
        M0 = M
        M0.p = 0; M0.cons = 1; M0.df = M0.N - 1; M0.ivar = 0
        x0 = J(rows(y), 0, .)
    }
    j = j0 = 1 // index of worst candidate
    for (i=1; i<=S.nsamp; i++) {
        // obtain fit from nonsingular subsample and apply refinement steps(s)
        b = rr_smpl(t); M.s_init = .
        r = y2 - rr_xb(X2, b, S.cons2)
        f = rr_irls(y, X, w, M, r)
        // optimize scale and keep hold of good candidates
        if (S.ivar) r = y - (rr_xb(X, f.b, M.cons) + f.u)
        else        r = y -  rr_xb(X, f.b, M.cons)
        if (_rr_s_check_scale(r, w, s[j], M)) {
            // optimize scale until convergence
            _rr_irls_s(f.scale, r, w, S.maxiter, M)
            // keep if better than worst candidate
            if (f.scale<s[j]) {
                B[j] = &f.b; s[j] = f.scale
                if (S.ivar) U[j] = &f.u
                j = order(s,1)[S.nkeep]
            }
        }
        // empty model
        if (null) {
            M0.b_init = y[rr_smpl_i(t)[1]] // (only need single obs)
            M0.s_init = .
            f = rr_irls(y, x0, w, M0)
            r = y :- f.b
            if (_rr_s_check_scale(r, w, s0[j0], M0)) {
                _rr_irls_s(f.scale, r, w, S.maxiter, M0)
                if (f.scale<s0[j0]) {
                    B0[j0] = f.b; s0[j0] = f.scale
                    j0 = order(s0,1)[S.nkeep]
                }
            }
        }
        if (S.dots) rr_progress(i, doti, S.nsamp)
    }
    if (S.dots) rr_progress_done(S.nsamp)

    // refinements
    // - refine selected candidates
    if (S.dots) rr_printf("{txt}refining {res}%g{txt} best candidates ", S.nkeep)
    M.cons = S.cons; M.maxiter = S.maxiter; M.relax = S.relax
    if (null) {; M0.maxiter = S.maxiter; M0.relax = S.relax; }
    j = j0 = 1
    for (i=1; i<=S.nkeep; i++) {
        M.b_init = *B[i]; M.s_init = s[i]
        if (S.ivar) r = y - (rr_xb(X, M.b_init, M.cons) + *U[i])
        else        r = y - rr_xb(X, M.b_init, M.cons)
        f = rr_irls(y, X, w, M, r)
        B[i] = &f.b; s[i] = f.scale
        if (S.ivar)  U[i] = &f.u
        if (s[i]<s[j]) j = i // index of best candidate
        // empty model
        if (null) {
            M0.b_init = B0[i]; M0.s_init = s0[i]
            f = rr_irls(y, x0, w, M0)
            B0[i] = f.b; s0[i] = f.scale
            if (s0[i]<s0[j0]) j0 = i // index of best candidate
        }
        if (S.dots) rr_printf(".")
    }
    
    // - final refinement of best candidate using full precision
    // empty model
    if (null) {
        M0.qd = S.qd; M0.dev = S.dev; M0.sconv = 0
        M0.b_init = B0[j0]; M0.s_init = s0[j0]
        f = rr_irls(y, x0, w, M0)
        S.b0 = std.ymed + std.ymadn * f.b // destd
        S.scale0 = f.scale * std.ymadn
    }
    M.qd = S.qd; M.dev = S.dev; M.sconv = 0
    M.b_init = *B[j]; M.s_init = s[j]
    if (S.ivar) r = y - (rr_xb(X, M.b_init, M.cons) + *U[j])
    else        r = y - rr_xb(X, M.b_init, M.cons)
    f = rr_irls(y, X, w, M, r)
    rr_destd(f.b, std)
    f.scale = f.scale * std.ymadn
    if (S.ivar) f.u = f.u * std.ymadn
    if (S.dots) rr_printf("{txt} done\n")
    return(f)
}

// - check whether candidate is worth considering
real scalar _rr_s_check_scale(real colvector r, real colvector w,
    real scalar smax, struct _rr_irls scalar S)
{
    if (smax>=.) return(1)
    return(editmissing(
        quadsum(w :* mm_biweight_rho(r / smax, S.k))/S.wsum // = mean()
        * (S.N / S.df), 0) <= S.delta)
}

// - variance estimation
void rr_s_V(real colvector r, real colvector y, real matrix X0, 
    real colvector w, struct rr scalar S)
{
    real scalar    c, d, p
    real colvector z, rho, psi, wphi
    real matrix    IF, Ainv
    pointer scalar X
    
    if (S.dots) rr_printf("{txt}computing standard errors ...")
    c = S.N / S.df
    z = r / S.f.scale
    psi  = mm_biweight_psi(z, S.k)
    wphi = w :* mm_biweight_phi(z, S.k)
    if (S.ivar & S.p) X = &(rr_demean(S.ginfo,X0,wphi) :+ mean(X0,wphi))
    else              X = &X0
    // computing Ginv using blockwise inversion:
    //     Ginv = (A^-1, -A^-1 * B / d) \ (0, 1/d)
    //  if    G = (A, B) \ (0, d)
    Ainv = rr_XXinv(*X, wphi, S.cons)
    d = quadsum(c * psi :* w :* z)
    S.Ginv = ((Ainv, -Ainv*quadcross(*X, S.cons, wphi, z, 0)/d) \
              (J(1,S.p+S.cons, 0), 1/d)) * S.f.scale
    if (S.vce) {
        rho = mm_biweight_rho(z, S.k)
        if      (S.ivar==1) p = S.p + S.cons // ivar() (df like xtreg,fe)
        else if (S.ivar==2) p = S.p + S.N_g  // absorb() (df like areg)
        else                p = S.p + S.cons // else
        IF = (psi:*(*X, J(rows(*X), S.cons, 1)), (c*rho:-S.delta)) * S.Ginv'
        S.V = rr_VCE(IF, w, S.fw, p, S.N, S.clust, S.N_clust)
        if (S.hm) rr_s_hm(IF, y, X0, w, S)
    }
    if (S.dots) rr_printf("{txt} done\n")
}

// - hausman test against LS
void rr_s_hm(real matrix IF, real colvector y, real matrix X, 
    real colvector w, struct rr scalar S)
{
    real scalar    p
    real colvector b, r
    real matrix    V
    transmorphic   t
    pointer scalar Xd
    
    // LS fit
    if (S.ivar) {
        t = _mm_areg(S.ginfo, y, X, w, S.qd)
        b = mm_areg_b(t)
        r = mm_areg_e(t)
        V = mm_areg_XXinv(t)
        Xd = &mm_areg_Xd(t)
        *Xd = *Xd :+ mm_areg_means(t) // this modifies t.Xd
    }
    else {
        t = mm_ls(y, X, w, S.cons, S.qd, S.dev)
        b = mm_ls_b(t)
        r = rr_resid(y, X, b, S.cons)
        V = mm_ls_XXinv(t)
    }
    // variance matrix of difference in IFs
    IF = IF[|1,1 \ .,S.p|] - ///
         ((r :* ((S.ivar ? *Xd : X), J(rows(X),S.cons,1))) * V')[|1,1 \ .,S.p|]
    if      (S.ivar==1) p = S.p + S.cons // ivar() (df like xtreg,fe)
    else if (S.ivar==2) p = S.p + S.N_g  // absorb() (df like areg)
    else                p = S.p + S.cons // else
    V = rr_VCE(IF, w, S.fw, p, S.N, S.clust, S.N_clust)
    // - test differences against zero
    b = S.f.b[|1\S.p|] - b[|1\S.p|]
    S.hm_chi2 = b' * invsym(V) * b
    if (S.ftest) {
        S.hm_chi2 = S.hm_chi2 / S.p // => F
        S.hm_p = Ftail(S.p, S.N_clust<. ? S.N_clust - 1 : S.df, S.hm_chi2)
    }
    else S.hm_p = chi2tail(S.p, S.hm_chi2)
}

/*---------------------------------------------------------------------------*/
// robreg mm
/*---------------------------------------------------------------------------*/

void rr_mm_scores()
{
    real scalar      k, c
    real colvector   y, e
    string rowvector v
    
    v = tokens(st_local("varlist"))
    y = st_data(., st_global("e(depvar)"), st_local("touse"))
    k = st_numscalar("e(k)")
    e = (y - st_data(., v[1], st_local("touse"))) / st_numscalar("e(scale)")
    st_store(., v[1], st_local("touse"), mm_biweight_psi(e, k))
    if (length(v)==1) return
    k = st_numscalar("e(kS)")
    e = (y - st_data(., v[2], st_local("touse"))) / st_numscalar("e(scale)")
    st_store(., v[2], st_local("touse"), mm_biweight_psi(e, k))
    c = st_numscalar("e(N)")
    c = c / (c - st_numscalar("e(df_m)") - (st_global("e(noconstant)")==""))
    st_store(., v[3], st_local("touse"), c * mm_biweight_rho(e, k) :- 
        st_numscalar("e(delta)"))
}

void rr_mm()
{
    real colvector   y, w, r
    real matrix      X
    struct rr scalar S
    
    // setup
    S = rr_setup(y=., X=., w=.)
    S.obf = "biweight"
    S.update = 0
    
    // settings of S estimator / starting values
    S.bp      = st_numscalar("e(bp)")
    S.delta   = st_numscalar("e(delta)")
    S.nsamp   = st_numscalar("e(nsamp)")
    S.nkeep   = st_numscalar("e(nkeep)")
    S.rsteps  = st_numscalar("e(rsteps)")
    S.s_init  = st_numscalar("e(scale)")
    if (S.r2) S.scale0 = st_numscalar("e(scale0)")
    S.bS      = st_matrix("e(b)")'
    S.x1      = st_global("e(m)")
    if (S.x1!="") {
        S.k1   = st_numscalar("e(m_k)")
        S.eff1 = st_numscalar("e(m_efficiency)")
    }
    if (st_numscalar("e(k_eq)")==3) {
        // estimate in memory is MM
        S.kS = st_numscalar("e(kS)")
        S.effS  = st_numscalar("e(effS)") 
        S.bS = S.bS[|(rows(S.bS)-1)/2+1 \ .|] // remove first equation
        if (S.r2) S.b0S = st_matrix("e(b0)")[2]
    }
    else {
        // estimate in memory is S
        S.kS = st_numscalar("e(k)")
        S.effS  = st_numscalar("e(efficiency)")
        if (S.r2) S.b0S = st_matrix("e(b0)")[1]
    }
    S.bS = S.bS[|1 \ rows(S.bS)-1|] // remove scale
    
    // tuning constant
    if (S.k>=.) S.k = mm_biweight_k(S.eff)
    if (S.k<S.kS) {
        display("{txt}(resetting tuning constant so that MM is not less efficient than S)")
        S.k = S.kS
    }
    S.eff = mm_biweight_eff(S.k) * 100
    
    // estimation
    S.b_init = (length(S.xindx) ? S.bS[S.xindx]    : J(0,1,.)) \ 
               (S.cons          ? S.bS[rows(S.bS)] : J(0,1,.))
    S.f = rr_irls(y, X, w, rr_irls_init(S))
    if (S.f.scale==0) r = J(rows(y), 1, 0)                // perfect fit
    else              r = y - rr_xb(X, S.f.b, S.cons)
    if (S.r2) rr_r2(r, y, w, S)
    if (S.se) rr_mm_V(r, y, X, w, S)
    
    // post results
    rr_isrtomitted(S)
    rr_post(S)
}

void rr_mm_empty(real colvector y, real colvector w, struct rr scalar S)
{   // constant-only fit using median or mean of Y as starting value, depending
    // on init() option; median will be used if custom starting values have been
    // specified in init(); MADN will be used as (starting value) for the scale
    struct rr_fit scalar  f
    struct _rr_irls scalar S0
    
    S0 = rr_irls_init(S)
    S0.s_init = S.scale0
    S0.b_init = S.b0S
    S0.cons = 1
    S0.p = 0
    S0.df = S0.N-1
    S0.dots = 0
    f = rr_irls(y, J(rows(y), 0, .), w, S0)
    S.b0     = f.b
}

void rr_mm_V(real colvector r, real colvector y, real matrix X,
    real colvector w, struct rr scalar S)
{
    real scalar    p, c, e
    real colvector z, psi, phi
    real colvector z0, rho0, psi0, phi0
    real matrix    IF, Ainv, Cinv
    
    if (S.dots) rr_printf("{txt}computing standard errors ...")
    c    = S.N / S.df
    z    = r / S.f.scale
    phi  = mm_biweight_phi(z, S.k)
    z0   = (y - rr_xb(X, S.b_init, S.cons)) / S.f.scale
    psi0 = mm_biweight_psi(z0, S.kS)
    phi0 = mm_biweight_phi(z0, S.kS)
    // computing Ginv using blockwise inversion:
    //     Ginv = (A^-1, 0, -A^-1*B/e) \ (0, C^-1, -C^-1*D/e) \ (0, 0, 1/e)
    //  if    G = (A, 0, B) \ (0, C, D) \ (0, 0, e)
    // see https://math.stackexchange.com/questions/2950054/inverse-of-a-3x3-block-matrix
    Ainv = rr_XXinv(X, phi:*w, S.cons)
    Cinv = rr_XXinv(X, phi0:*w, S.cons)
    e    = quadsum(c * psi0 :* w :* z0)
    p    = S.p+S.cons
    S.Ginv = ((Ainv, J(p, p, 0), -Ainv*quadcross(X, S.cons, phi:*w, z, 0)/e) \
              (J(p, p, 0), Cinv, -Cinv*quadcross(X, S.cons, phi0:*w, z0, 0)/e) \
              (J(1, p, 0), J(1, p, 0), 1/e)) * S.f.scale
    if (S.vce) {
        psi  = mm_biweight_psi(z, S.k)
        rho0 = mm_biweight_rho(z0, S.kS)
        IF = (psi:*(X, J(rows(X), S.cons, 1)), psi0:*(X, J(rows(X), S.cons, 1)),
             (c*rho0:-S.delta)) * S.Ginv'
        S.V = rr_VCE(IF, w, S.fw, S.p+S.cons, S.N, S.clust, S.N_clust)
        if (S.hm) rr_mm_hm(S)
    }
    if (S.dots) rr_printf("{txt} done\n")
}

void rr_mm_hm(struct rr scalar S)
{
    real colvector b
    real matrix    R
    
    b = S.f.b \ S.b_init \ S.f.scale
    R = I(S.p), J(S.p, S.cons, 0)
    R = R, -R, J(S.p, 1, 0)
    S.hm_chi2 = (R*b)' * invsym(R*S.V*R') * (R*b)
    if (S.ftest) {
        S.hm_chi2 = S.hm_chi2 / S.p // => F
        S.hm_p = Ftail(S.p, S.N_clust<. ? S.N_clust - 1 : S.df, S.hm_chi2)
    }
    else S.hm_p = chi2tail(S.p, S.hm_chi2)
}

/*---------------------------------------------------------------------------*/
// robreg lqs/lms/lts
/*---------------------------------------------------------------------------*/

void rr_lqs()
{
    real colvector   y, w
    real matrix      X
    struct rr scalar S
    
    // setup
    S = rr_setup(y=., X=., w=.)
    
    // subset size for LTS and LQS
    rr_lqs_h(S)
    
    // number of subsamples
    if (S.nsamp>=.) rr_nsamp(S.p, (S.cmd=="lts" ? 50 : 500), 10000, S)
    if (S.nkeep>S.nsamp) S.nkeep = S.nsamp // only relevant for lts
    
    // estimation
    if (S.cmd=="lts") S.f = _rr_lts(y, X, w, S)
    else              S.f = _rr_lqs(y, X, w, S)
    rr_lqs_scale(y, X, w, S)
    
    // post results
    rr_isrtomitted(S)
    rr_post(S)
}

void rr_lqs_h(struct rr scalar S)
{
    if (S.cmd!="lms") {
        // see Rousseeuw and Leroy (1987), p. 134; we express h as a proportion
        // instead of an absolute number of observations
        S.h  = (floor((1-S.bp/100)*S.N) + floor(S.bp/100*(S.p+S.cons+1))) / S.N
        S.h0 = (floor((1-S.bp/100)*S.N) + floor(S.bp/100*(1+1))) / S.N
    }
    else S.h = S.h0 = .5 // use plain median for LMS
}

void rr_lqs_scale(real colvector y, real matrix X, real colvector w,
    struct rr scalar S)
{
    real scalar    p
    real colvector r, q
    
    p = S.p + S.cons
    S.f.scale = .
    r = rr_resid(y, X, S.f.b, S.cons, S.f.scale) // sets scale=0 if perfect fit
    if (S.f.scale==0) return
    q = select(1::rows(r), abs(r):<=(2.5*S.s0))
    if (w==1) S.f.scale = sqrt(sum(r[q]:^2)         / (rows(q)   - p))
    else      S.f.scale = sqrt(sum(w[q] :* r[q]:^2) / (sum(w[q]) - p))
    _editmissing(S.f.scale, 0)
}

struct rr_fit scalar _rr_lqs(real colvector y0, real matrix X0, real colvector w,
    struct rr scalar S)
{
    real scalar    i, c, doti,  null
    real colvector y, b, e2
    real matrix    X
    transmorphic   t
    struct rr_fit scalar f, f0
    struct rr_std_struct scalar std
    
    // whether to include estimation of empty model
    null = (S.r2 & (S.p | S.cons))
    
    // standardize data (to increase numerical stability)
    y = y0; X = X0
    std = rr_std(y, X, w, S.cons, S.nostd)
    
    // enumerate candidates
    if (S.dots) doti = rr_progress_init(S.nsamp)
    t = rr_smpl_init(y, X, S.p, S.cons, S.smpl)
    for (i=1; i<=S.nsamp; i++) {
        // full model
        b = rr_smpl(t)
        e2 = (y - rr_xb(X, b, S.cons)):^2
        c = mm_quantile(e2, w, S.h)
        if (c < f.scale) {
            f.W = rr_smpl_i(t) // indices of subset
            f.b = b; f.scale = c
        }
        // empty model
        if (null) {
            b = y[rr_smpl_i(t)[1]] // (only need single obs)
            e2 = (y :- b):^2
            c = mm_quantile(e2, w, S.h0)
            if (c < f0.scale) {; f0.b = b; f0.scale = c; }
        }
        if (S.dots) rr_progress(i, doti, S.nsamp)
    }
    if (S.dots) rr_progress_done(S.nsamp)
    
    // final fit (not really needed; just for sake of precision)
    f.b = mm_ls_b(mm_ls(y[f.W], X[f.W,], (w==1 ? w : w[f.W]), S.cons, S.qd, S.dev))
    rr_destd(f.b, std)
    f.scale = f.scale * std.ymadn^2
    S.c = f.scale // copy optimization criterion
    S.s0 = rr_lqs_s0(S.cmd, f.scale, S.h, S.N - S.p - S.cons)
    // store h-quantile of squared residuals
    S.q_h = mm_quantile((y0 - rr_xb(X0, f.b, S.cons)):^2, w, S.h)
    
    // R-squared (Rousseeuw/Hubert 1997)
    if (S.r2) {
        if (null) {
            f0.b = std.ymed + std.ymadn * f0.b // destd
            f0.scale = f0.scale * std.ymadn^2
            S.b0 = f0.b
            S.scale0 = rr_lqs_s0(S.cmd, f0.scale, S.h0, S.N-1)
        }
        else { // (full model = empty model)
            S.b0 = f.b
            S.scale0 = S.s0 // [sic!]
        }
        S.R2 = 1 - editmissing(S.s0^2 / S.scale0^2,0)
    }
    return(f)
}

real scalar rr_lqs_s0(string scalar cmd, real scalar c, real scalar h, real scalar df)
{
    real scalar z
    
    if (cmd=="lms") return(sqrt(c) / invnormal(0.75) * (1 + 5/max((df, 1))))
    if (cmd=="lqs") return(sqrt(c) / invnormal((1 + h)/2))
    // if (cmd=="lts"):
    z = invnormal((1 + h)/2)
    return(sqrt(c) / sqrt(1 - 2*z/h * normalden(z)))
}

struct rr_fit scalar _rr_lts(real colvector y0, real matrix X0, real colvector w,
    struct rr scalar S)
{
    real scalar    i, j, k, k0, c, doti, n, null
    real colvector y, b, b0, e2, h, Indx
    real matrix    X
    transmorphic   t
    struct rr_fit colvector f, f0
    struct rr_std_struct scalar std

    // whether to include estimation of empty model
    null = (S.r2 & (S.p | S.cons))
    
    // standardize data (to increase numerical stability)
    y = y0; X = X0
    std = rr_std(y, X, w, S.cons, S.nostd)
    
    // enumerate candidates
    if (S.dots) doti = rr_progress_init(S.nsamp)
    n = rows(y); Indx = 1::n
    t = rr_smpl_init(y, X, S.p, S.cons, S.smpl)
    f = rr_fit(S.nkeep); f0 = rr_fit(S.nkeep);
    k = k0 = 1 // index of worst candidate
    for (i=1; i<=S.nsamp; i++) {
        // full model
        b = rr_smpl(t)
        e2 = (y - rr_xb(X, b, S.cons)):^2
        for (j=1;j<=S.csteps;j++) {
            b0 = b
            h = select(Indx, e2:<=mm_quantile(e2, w, S.h))
            b = mm_ls_b(mm_ls(y[h], X[h,], (w==1 ? w : w[h]), S.cons, 0, 0))
            e2 = (y - rr_xb(X, b, S.cons)):^2
            if (mreldif(b,b0)<S.tol) break
        }
        c = mean(e2, w:*(e2:<=mm_quantile(e2, w, S.h)))
        if (c < f[k].scale) {
            //f[k].W = (S.csteps ? h : rr_smpl_i(t)) // indices of subset
            f[k].b = b; f[k].scale = c
            for (j=S.nkeep;j;j--) {; if (f[j].scale>f[k].scale) k = j; }
        }
        // empty model
        if (null) {
            b = y[rr_smpl_i(t)[1]] // (only need single obs)
            e2 = (y :- b):^2
            for (j=1;j<=S.csteps;j++) {
                b0 = b
                h = select(Indx, e2:<=mm_quantile(e2, w, S.h0))
                b = mean(y[h], (w==1 ? w : w[h]))
                e2 = (y :- b):^2
                if (reldif(b,b0)<S.tol) break
            }
            c = mean(e2, w:*(e2:<=mm_quantile(e2, w, S.h0)))
            if (c < f0[k0].scale) {
                f0[k0].b = b; f0[k0].scale = c
                for (j=S.nkeep;j;j--) {; if (f0[j].scale>f0[k0].scale) k0 = j; }
            }
        }
        if (S.dots) rr_progress(i, doti, S.nsamp)
    }
    if (S.dots) rr_progress_done(S.nsamp)
    
    // refine selected candidates
    if (S.dots) rr_printf("{txt}refining {res}%g{txt} best candidates ", S.nkeep)
    k = k0 = 1   // index of best candidate
    for (i=1; i<=S.nkeep; i++) {
        // full model
        b = f[i].b
        e2 = (y - rr_xb(X, b, S.cons)):^2
        for (j=1;j<=S.maxiter;j++) {
            b0 = b
            h = select(Indx, e2:<=mm_quantile(e2, w, S.h))
            b = mm_ls_b(mm_ls(y[h], X[h,], (w==1 ? w : w[h]), S.cons, S.qd, S.dev))
            e2 = (y - rr_xb(X, b, S.cons)):^2
            if (mreldif(b,b0)<S.tol) break
        }
        if (j>S.maxiter & S.relax==0) exit(error(430))
        f[i].b = b
        f[i].scale = mean(e2, w:*(e2:<=mm_quantile(e2, w, S.h)))
        if (f[i].scale<f[k].scale) k = i
        // empty model
        if (null) {
            b = f0[i].b
            e2 = (y :- b):^2
            for (j=1;j<=S.maxiter;j++) {
                b0 = b
                h = select(Indx, e2:<=mm_quantile(e2, w, S.h0))
                b = mean(y[h], (w==1 ? w : w[h]))
                e2 = (y :- b):^2
                if (reldif(b,b0)<S.tol) break
            }
            if (j>S.maxiter & S.relax==0) exit(error(430))
            f0[i].b = b
            f0[i].scale = mean(e2, w:*(e2:<=mm_quantile(e2, w, S.h0)))
            if (f0[i].scale<f0[k0].scale) k0 = i
        }
        if (S.dots) rr_printf(".")
    }
    if (S.dots) rr_printf("{txt} done\n")
    
    // destandardize final solution
    rr_destd(f[k].b, std)
    f[k].scale = f[k].scale * std.ymadn^2
    S.c = f[k].scale // copy optimization criterion
    S.s0 = rr_lqs_s0(S.cmd, f[k].scale, S.h, S.N - S.p - S.cons)
    // store h-quantile of squared residuals
    S.q_h = mm_quantile((y0 - rr_xb(X0, f[k].b, S.cons)):^2, w, S.h)
    
    // R-squared (Rousseeuw/Hubert 1997)
    if (S.r2) {
        if (null) {
            S.b0 = std.ymed + std.ymadn * f0[k0].b // destd
            S.scale0 = rr_lqs_s0(S.cmd, f0[k0].scale*std.ymadn^2, S.h0, S.N-1)
        }
        else { // (full model = empty model)
            S.b0 = f[k].b
            S.scale0 = S.s0 // [sic!]
        }
        S.R2 = 1 - editmissing(S.s0^2 / S.scale0^2,0)
    }
    return(f[k])
}

end

