*! version 1.0.5  15mar2025  Ben Jann

local rc 0
capt findfile lmoremata.mlib
if _rc {
    di as error "the {bf:moremata} package is required; type {stata ssc install moremata, replace}"
    error 499
}

program robstat, eclass properties(svyb svyj)
    version 11
    if replay() {
        Display `0'
        exit
    }
    local version : di "version " string(_caller()) ":"
    Parse_opts `0' // returns lhs, options, statistics, jbtest, jbtest2, jbwald, cluster
    `version' _vce_parserun robstat, mark(over) bootopts(`cluster') ///
        jkopts(`cluster') wtypes(pw iw fw) noeqlist: ///
        `lhs', nose `statistics' `options'
    if "`s(exit)'" != "" {
        ereturn local cmdline `"robstat `0'"'
        if "`jbtest'"!="" {
            JBtest, `jbtest2' `jbwald' display
        }
        exit
    }
    Estimate `0' // returns diopts
    ereturn local cmdline `"robstat `0'"'
    if "`jbtest'"!="" {
        JBtest, `jbtest2' `jbwald'
    }
    Display, `diopts'
    if `"`e(IFvars)'"'!="" {
        local IFnote "(influence functions stored in: `e(IFvars)')"
        local i 0
        while (1) {
            local ++i
            local line: piece `i' 80 of "`IFnote'"
            if "`line'"=="" continue, break
            di as txt "`line'"
        }
        di
    }
end

program Parse_opts
    _parse comma lhs 0 : 0
    syntax [, nose CLuster(passthru) Statistics(str) swap ///
        JBtest JBtest2(str) WALD  * ]
    if `"`jbtest2'"'!="" local jbtest jbtest
    if "`jbtest'"!="" & `"`statistics'"'!="" {
        di as err "statistics() not allowed with jbtest"
        exit 198
    }
    if "`jbtest'"!="" & "`swap'"!="" {
        di as err "swap not allowed with jbtest"
        exit 198
    }
    if "`wald'"!="" & "`jbtest'"=="" {
        di as err "wald only allowed if jbtest is specified"
        exit 198
    }
    if "`jbtest'"!="" JBtest_args `jbtest2' // sets local statistics
    c_local lhs `"`lhs'"'
    c_local cluster `cluster'
    c_local jbtest `jbtest'
    if "`jbtest2'"!="" {
        c_local jbtest2 jbtest2(`jbtest2')
    }
    c_local jbwald `wald'
    if "`statistics'"!="" {
        c_local statistics statistics(`statistics')
    }
    c_local options `swap' `options'
end

program Display
    syntax [, noHEader noTABle Level(passthru) CILog * ]
    if "`cilog'"!="" {
        if c(stata_version)<15 {
            di as err "option cilog only allowed in Stata 15 or newer"
            exit 198
        }
    }
    _get_diopts diopts, `options'
    if `"`e(cmd)'"'!="robstat" {
        di as err "last robstat results not found"
        exit 301
    }
    if `"`level'"'=="" local level level(`e(level)')
    if `"`header'"'=="" {
        if c(stata_version)>=12 {
            nobreak {
                Display_ereturn local cmd "total" // mimick header of -total-
                capture noisily break {
                    _coef_table_header
                }
                Display_ereturn local cmd "robstat"
                if _rc exit _rc
            }
        }
        else _coef_table_header
        if `"`e(over)'"'!="" {
            _svy_summarize_legend
        }
        else di ""
    }
    if `"`table'"'=="" {
        if "`cilog'"!="" {
            mata: st_local("cilog", "cilog" * anyof(st_matrix("e(class)"),2))
        }
        nobreak {
            local depvar `"`e(depvar)'"'
            local modified 0
            if e(N_stats)==1 {
                if e(N_vars)>1 | `"`e(over)'"'!="" {
                    Display_ereturn local depvar `"`e(statistics)'"'
                    local modified 1
                }
            }
            capture noisily break {
                Display_table "`cilog'" `"`level'"' `"`options'"'
            }
            if `modified' {
                Display_ereturn local depvar `"`depvar'"'
            }
            if _rc exit _rc
        }
    }
    capt confirm matrix e(jbtest)
    if _rc==0 JBtest_display
end
prog Display_ereturn, eclass
    ereturn `0'
end
program Display_table
    args cilog level options
    if c(stata_version)>=15 {
        if "`cilog'"!="" {
            qui _coef_table, `level'
            tempname CI
            mata: robstat_cilog()
            _coef_table, nopvalue cimat(`CI') `level' `options'
            mat drop `CI'
            di as txt `"(`cilognote')"'
        }
        else {
            eret di, nopvalue `level' `options'
        }
    }
    else if c(stata_version)>=14 {
        eret di, nopvalue `level' `options'
    }
    else if c(stata_version)>=13 {
        quietly update
        if r(inst_ado)>=d(26jun2014) {
            eret di, nopvalue `level' `options'
        }
        else {
            _coef_table, cionly `level' `options'
        }
    }
    else if c(stata_version) >= 12 {
        _coef_table, cionly `level' `options'
    }
    else {
        eret di, `level' `options'
    }
end

program JBtest, eclass
    syntax [, jbtest2(str) WALD display ]
    JBtest_args `jbtest2'
    local vce   "`e(vce)'"
    local wtype "`e(vce)'"
    if "`vce'"=="" {
        if "`wtype'"!="" & "`wtype'"!="fweight" local wald wald
    }
    else if "`vce'"!="analytic" local wald wald
    local ntests: list sizeof jbtests
    local eqs: coleq e(b)
    local eqs: list uniq eqs
    if "`wald'"!="" {
        if e(df_r)<. {
            local jbtype F
            local jbtitle "Normality Tests (Wald F; df_r = `e(df_r)')"
        }
        else {
            local jbtype chi2
            local jbtitle "Normality Tests (Wald chi2)"
        }
        tempname jbtest tmp
        foreach eq of local eqs {
            local rown
            matrix `tmp' = J(`ntests', 3,.)
            local m 0
            foreach t of local jbtests {
                local ++m
                if "`t'"=="jbera" {
                    local rown `rown' JB
                    local exp (_b[`eq':skewness]=0) (_b[`eq':kurtosis]=3)
                }
                else if "`t'"=="moors" {
                    local rown `rown' MOORS
                    local exp (_b[`eq':SK25]=0) (_b[`eq':QW25]=1.23)
                }
                else if "`t'"=="mc" {
                    local rown `rown' MC
                    local exp (_b[`eq':MC]=0)
                }
                else if "`t'"=="lmc" {
                    local rown `rown' LMC
                    local exp (_b[`eq':LMC]=0.199)
                }
                else if "`t'"=="rmc" {
                    local rown `rown' RMC
                    local exp (_b[`eq':RMC]=0.199)
                }
                else if "`t'"=="lr" {
                    local rown `rown' LR
                    local exp (_b[`eq':LMC]=0.199) (_b[`eq':RMC]=0.199)
                }
                else if "`t'"=="mcl" {
                    local rown `rown' MC-L
                    local exp (_b[`eq':MC]=0) (_b[`eq':LMC]=0.199)
                }
                else if "`t'"=="mcr" {
                    local rown `rown' MC-R
                    local exp (_b[`eq':MC]=0) (_b[`eq':RMC]=0.199)
                }
                else if "`t'"=="mclr" {
                    local rown `rown' MC-LR
                    local exp (_b[`eq':MC]=0) (_b[`eq':LMC]=0.199) (_b[`eq':RMC]=0.199)
                }
                qui test `exp'
                matrix `tmp'[`m',1] = r(`jbtype'), r(df), r(p)
            }
            mat rown `tmp' = `rown'
            mat roweq `tmp' = `eq'
            mat `jbtest' = nullmat(`jbtest') \ `tmp'
        }
        mat coln `jbtest' = `jbtype' df "Prob>`jbtype'"
    }
    else {
        local nover = e(N_over)
        local jbtype chi2
        local jbtitle "Normality Tests"
        tempname jbtest tmp D V
        local k 0
        foreach eq of local eqs {
            local ++k
            local N = el(e(_N), mod(`k'-1,`nover')+1, 1)
            local rown
            matrix `tmp' = J(`ntests', 3,.)
            local m 0
            foreach t of local jbtests {
                local ++m
                if "`t'"=="jbera" {
                    local rown `rown' JB
                    local df 2
                    matrix `D' = (_b[`eq':skewness], _b[`eq':kurtosis]-3)'
                    matrix `V' = (6, 0) \ (0, 24)
                }
                else if "`t'"=="moors" {
                    local rown `rown' MOORS
                    local df 2
                    matrix `D' = (_b[`eq':SK25], _b[`eq':QW25]-1.23)'
                    matrix `V' = (1.84, 0) \ (0, 3.14)
                }
                else if "`t'"=="mc" {
                    local rown `rown' MC
                    local df 1
                    matrix `D' = (_b[`eq':MC])
                    matrix `V' = (1.25)
                }
                else if "`t'"=="lmc" {
                    local rown `rown' LMC
                    local df 1
                    matrix `D' = (_b[`eq':LMC]-0.199)
                    matrix `V' = (2.62)
                }
                else if "`t'"=="rmc" {
                    local rown `rown' RMC
                    local df 1
                    matrix `D' = (_b[`eq':RMC]-0.199)
                    matrix `V' = (2.62)
                }
                else if "`t'"=="lr" {
                    local rown `rown' LR
                    local df 2
                    matrix `D' = (_b[`eq':LMC]-0.199, _b[`eq':RMC]-0.199)'
                    matrix `V' = (2.62, -.0123) \ (-.0123, 2.62)
                }
                else if "`t'"=="mcl" {
                    local rown `rown' MC-L
                    local df 2
                    matrix `D' = (_b[`eq':MC], _b[`eq':LMC]-0.199)'
                    matrix `V' = (1.25, .323) \ (.323, 2.62)
                }
                else if "`t'"=="mcr" {
                    local rown `rown' MC-R
                    local df 2
                    matrix `D' = (_b[`eq':MC], _b[`eq':RMC]-0.199)'
                    matrix `V' = (1.25, .323) \ (.323, 2.62)
                }
                else if "`t'"=="mclr" {
                    local rown `rown' MC-LR
                    local df 3
                    matrix `D' = (_b[`eq':MC], _b[`eq':LMC]-0.199, _b[`eq':RMC]-0.199)'
                    matrix `V' = (1.25, .323, -.323) \  ///
                                 (.323, 2.62, -.0123) \ ///
                                 (-.323, -.0123, 2.62)
                }
                matrix `tmp'[`m',1] = `N'*`D''*invsym(`V')*`D', `df'
                matrix `tmp'[`m',3] = chi2tail(`df', `tmp'[`m',1])
            }
            mat rown `tmp' = `rown'
            mat roweq `tmp' = `eq'
            mat `jbtest' = nullmat(`jbtest') \ `tmp'
        }
        mat coln `jbtest' = `jbtype' df "Prob>`jbtype'"
        
    }
    ereturn matrix jbtest = `jbtest'
    ereturn local jbwald `wald'
    ereturn local jbtype `jbtype'
    ereturn local jbtitle "`jbtitle'"
    if "`display'"!="" JBtest_display
end
program JBtest_args
    if strtrim(`"`0'"')=="all" {
        local 0 jbera moors mclr mcl mcr mc lr lmc rmc
    }
    local jbtests
    foreach s of local 0 {
        local t = lower(`"`s'"')
        local l  = strlen(`"`t'"')
        // jbera
        if "`t'"==substr("jbera", 1, max(2,`l')) {
            local jbtests `jbtests' jbera
            local s1 skewness kurtosis
        }
        else if "`t'"==substr("moors", 1, max(2,`l')) {
            local jbtests `jbtests' moors
            local s2 sk25 qw25
        }
        else if "`t'"=="mc" {
            local jbtests `jbtests' mc
            local s3 mc
        }
        else if "`t'"==substr("lmc", 1, max(1,`l')) {
            local jbtests `jbtests' lmc
            local s4 lmc
        }
        else if "`t'"==substr("rmc", 1, max(1,`l')) {
            local jbtests `jbtests' rmc
            local s5 rmc
        }
        else if "`t'"=="lr" {
            local jbtests `jbtests' lr
            local s4 lmc
            local s5 rmc
        }
        else if inlist("`t'", "mcl", "mc-l") {
            local jbtests `jbtests' mcl
            local s3 mc
            local s4 lmc
        }
        else if inlist("`t'", "mcr", "mc-r") {
            local jbtests `jbtests' mcr
            local s3 mc
            local s5 rmc
        }
        else if inlist("`t'", "mclr", "mc-lr") {
            local jbtests `jbtests' mclr
            local s3 mc
            local s4 lmc
            local s5 rmc
        }
        else {
            di as err `"`s' not allowed in jbtest()"'
            exit 198
        }
    }
    if "`jbtests'"=="" {
        local jbtests jbera moors mclr
        local statistics skewness kurtosis sk25 qw25 mc lmc rmc
    }
    else {
        local statistics `s1' `s2' `s3' `s4' `s5'
    }
    c_local statistics `statistics'
    c_local jbtests `jbtests'
end

program JBtest_display
    local rspec
    local k_eq = e(k_eq)
    local njb  = rowsof(e(jbtest)) / `k_eq' - 1
    forv i = 1/`k_eq' {
        forv j = 1/`njb' {
            local rspec `rspec'&
        }
        local rspec `rspec'-
    }
    matlist e(jbtest), rspec(--`rspec') cspec(&%12s|%10.2f&%5.0g&%10.4f&) ///
        title(`e(jbtitle)')
end

program Estimate, eclass
    // syntax
    syntax varlist(numeric) [if] [in] [pw iw fw/], [          ///
        Statistics(str asis) swap                             ///
        over(varname numeric) Total                           ///
        vce(str) CLuster(varname) svy SVY2(str) nose          ///
        GENerate GENerate2(name) replace                      ///
        /// normality test (just for parsing)
        JBtest JBtest2(str) WALD                              ///
        /// optimization options for M-estimation
        TOLerance(real 1e-10) ITERate(integer `c(maxiter)')   ///
        /// kernel density estimation options
        Kernel(name) bw(name) Adaptive(int 2) n(int 512)      ///
        /// display options
        Level(cilevel) noHEader noTABle CILog *               ///
        ]
    if "`cilog'"!="" {
        if c(stata_version)<15 {
            di as err "option cilog only allowed in Stata 15 or newer"
            exit 198
        }
    }
    if `"`generate2'"'!=""   local generate generate
    else if "`generate'"!="" local generate2 _IF_
    if `"`jbtest'`jbtest2'"'!="" {
        JBtest_args `jbtest2' // sets local statistics
    }
    if `tolerance'<=0 {
            di as err  "tolerance() must be positive"
            exit 198
    }
    if `iterate'<=0 {
            di as err  "iterate() must be positive"
            exit 198
    }
    local estopts tolerance(`tolerance') iterate(`iterate')
    if "`kernel'"=="" local kernel epan2
    if "`bw'"=="" local bw dpi
    if `adaptive'<0 {
        di as err "adaptive() must be positive"
        exit 198
    }
    if `n'<=2 {
        di as err "n() must be > 2"
        exit 198
    }
    local estopts `estopts' kernel(`kernel') bw(`bw') adaptive(`adaptive') n(`n')

    // varlist
    local varlist: list uniq varlist // remove repeated varnames
    local ndepv: list sizeof varlist 
    
    // statistics
    Parse_stats `statistics'    // returns stats, statslbl
    local nstats: list sizeof stats
    
    // over(), total
    if "`over'"=="" {
        if "`total'"!="" {
            di as err "total only allowed if over() is specified"
            exit 198
        }
    }
    
    // vce
    local vce0 `"`vce'"'
    if `"`cluster'"'!="" {
        if "`se'"!="" {
            di as err "cluster() and nose not both allowed"
            exit 198
        }
        if `"`svy'`svy2'"'!="" {
            di as err "cluster() and svy() not both allowed"
            exit 198
        }
        if `"`vce'"'!="" {
            di as err "cluster() and vce() not both allowed"
            exit 198
        }
        local vce `"cluster `cluster'"'
        local cluster
    }
    if `"`vce'"'!="" {
        if "`se'"!="" {
            di as err "vce() and nose not both allowed"
            exit 198
        }
        if `"`svy'`svy2'"'!="" {
            di as err "vce() and svy() not both allowed"
            exit 198
        }
        gettoken vce clustvar : vce
        if `"`vce'"'=="analytic" & `"`clustvar'"'=="" {
            local vce analytic
        }
        else if `:list sizeof clustvar'==1 & ///
            substr("cluster", 1, max(2, strlen(`"`vce'"')))==`"`vce'"' {
            local vce cluster
            local vcetype Robust
            gettoken clustvar : clustvar
            local clustopt cluster(`clustvar')
        }
        else {
            di as err "invalid vce()"
            exit 198
        }
    }
    else if "`se'"=="" {
        local vce analytic
    }
    
    // svy 
    if `"`svy'`svy2'"'!="" {
        if "`weight'"!="" {
            di as err "weights not allowed with svy; supply weights to {help svyset}"
            exit 101
        }
        if "`se'"!="" {
            di as err "svy() and nose not both allowed"
            exit 198
        }
        local svy svy
        if `"`svy2'"'!="" {
            local svy2 `"subpop(`svy2')"'
        }
    }
    
    // display options
    local levelopt level(`level')
    _get_diopts diopts, `options'
    c_local diopts `header' `table' `levelopt' `cilog' `diopts'
    
    // sample and weights
    marksample touse
    markout `touse' `clustvar' `over'
    if "`svy'"!="" {
        if c(stata_version)>=14 {
            tempvar subpop exp
            _svy_setup `touse' `subpop' `exp', svy `svy2'
            local weight `"`r(wtype)'"'
            if "`weight'"=="" {
                drop `exp'
                local exp
            }
        }
        else {
            tempvar subpop
            _svy_setup `touse' `subpop', svy `svy2'
            local weight `"`r(wtype)'"'
            local exp `"`r(wvar)'"'
        }
        if `"`r(vce)'"'!="linearized" {
            di as err "option svy is only allowed if VCE is set to linearized; " ///
                `"use the {helpb svy} prefix command for `r(vce)' survey estimation"'
            exit 498
        }
        local svy_posts `"`r(poststrata)'"'
        local svy_postw `"`r(postweight)'"'
        if `"`svy_posts'"'!="" {
            if "`weight'"!="" local wexp `"[`weight' = `exp']"'
            tempvar exp
            svygen post double `exp' `wexp' if `touse', ///
                posts(`svy_posts') postw(`svy_postw')
            if "`weight'"=="" local weight pweight
        }
    }
    else local subpop `touse'
    if "`over'"!="" {
        capt assert ((`over'==floor(`over')) & (`over'>=0)) if `subpop'
        if _rc {
            di as err "variable in over() must be integer and nonnegative"
            exit 452
        }
        qui levelsof `over' if `subpop', local(overvals)
        local N_over: list sizeof overvals
        if "`total'"!="" {
            local ++N_over
        }
        local over_labels
        foreach overval of local overvals {
            local over_labels `"`over_labels' `"`: label (`over') `overval''"'"'
        }
        local over_labels: list clean over_labels
    }
    else {
        local total total
        local N_over 1
    }
    if "`weight'"!="" {
        capt confirm variable `exp'
        if _rc {
            local wexp `"= `exp'"'
            tempvar exp
            qui gen double `exp' `wexp'
        }
        local wgt `"[`weight' = `exp']"'
        if "`weight'"=="pweight" {
            local swgt `"[aw = `exp']"'
        }
        else {
            local swgt `"`wgt'"'
        }
    }
    else {
        local wgt
        local swgt
    }
    if "`svy'"!="" & `"`exp'"'!="" { // include obs with zero weight
        su `touse' if `touse', meanonly
    }
    else {
        su `touse' `swgt' if `touse', meanonly
    }
    local N = r(N)
    if `N'==0 error 2000
    if `"`over'"'!="" {
        if "`weight'"!="" {
            su `touse' `swgt' if `touse' & `subpop', meanonly
            local W = r(sum_w)
        }
        else local W `N'
    }
    
    // check whether variance estimation is supported
    if "`se'"=="" {
        if "`weight'"=="fweight" {
            if "`vce'"=="analytic" & `"`vce0'"'=="" {
                di as txt "(variance estimation not supported with fweights)"
                local se nose
            }
            else if "`svy'`vce'"!="" {
                di as err "variance estimation not supported with fweights"
                exit 498
            }
        }
    }
    
    // generate: check whether variables already exist
    if "`se'"=="" & "`generate'"!="" & "`replace'"=="" {
        foreach v of local varlist {
            foreach overval in `overvals' `total' {
                foreach stat of local stats {
                    Make_IF_Name `generate2' `stat' `v' `ndepv' "`over'" ///
                        `overval' `stat' `nstats' // returns vname
                    confirm new variable `vname'
                }
            }
        }
    }
    
    // compute statistics
    tempname b btmp class cltmp aux auxtmp _N
    local uvars
    if `nstats'>1 {
        local k_eq   = `ndepv' * `N_over'
        local k_coef = `nstats'
    }
    else {
        if "`over'"!="" {
            local k_eq   = `ndepv'
            local k_coef = `N_over'
        }
        else {
            local k_eq   = 1
            local k_coef = `ndepv'
        }
    }
    if "`over'"!="" {
        mat `_N' = J(`N_over', 1, .)
    }
    else {
        mat `_N' = J(1, 1, .)
    }
    mat rown `_N' = `overvals' `total'
    mat coln `_N' = "N"
    if `"`over'"'!="" {
        if "`weight'"!="" {
            tempname _W
            mat `_W' = `_N'
        }
        else local _W `_N'
    }
    foreach v of local varlist {
        local k 0
        foreach overval in `overvals' `total' {
            local ++k
            // select obs
            if `"`overval'"'=="total" local touse1 (1)
            else                      local touse1 (`over'==`overval')
            // equation label
            if `k_eq'>1 {
                if `ndepv'==1        local eq "`overval'"
                else if "`over'"=="" local eq "`v'"
                else if `nstats'==1  local eq "`v'"
                else                 local eq "`v'_`overval'"
            }
            else if "`over'"!="" & `nstats'>1 local eq "`overval'"
            else local eq
            // count obs
            if "`svy'"!="" & `"`exp'"'!="" { // include obs with zero weight
                su `touse' if `touse' & `subpop' & `touse1', meanonly
            }
            else {
                su `touse' `swgt' if `touse' & `subpop' & `touse1', meanonly
            }
            mat `_N'[`k', 1] = r(N)
            if `"`over'"'!="" {
                if "`weight'"!="" {
                    if "`svy'"!="" & `"`exp'"'!="" {
                        su `touse' `swgt' if `touse' & `subpop' & `touse1',/*
                            */ meanonly
                    }
                    mat `_W'[`k', 1] = r(sum_w)
                }
            }
            // compute stats
            mat `btmp' = J(1, `nstats', .)
            mat coln `btmp' = `statslbl'
            mat `cltmp' = `btmp'
            if `nstats'==1 {
                if "`over'"!="" {
                    mat coln `btmp' = `overval'
                }
                else if `ndepv'>1 {
                    mat coln `btmp' = `v'
                }
            }
            mat coleq `btmp' = `eq'
            mat `auxtmp' = `btmp'
            local j 0
            foreach stat of local stats {
                local u
                if "`se'"=="" {
                    tempvar u
                    qui gen double `u' = 0 if `touse'
                    local uvars `uvars' `u'
                }
                local ++j
                Estimate_`stat' `wgt' if `touse' & `subpop' & `touse1', ///
                    v(`v') u(`u') `estopts'
                if `"`over'"'!="" { // rescale IF
                    qui replace `u' = `u' * (`W'/`_W'[`k', 1])
                }
                mat `btmp'[1, `j']   = r(b)
                mat `cltmp'[1, `j']  = r(class)
                mat `auxtmp'[1, `j'] = r(k)
            }
            mat `b'     = nullmat(`b'), `btmp'
            mat `class' = nullmat(`class'), `cltmp'
            mat `aux'   = nullmat(`aux'), `auxtmp'
        }
    }
    
    // compute standard errors
    if "`se'"=="" {
        tempname V
        if "`svy'"!="" {
            //qui svy, `svy2': total `uvars' if `touse'
            qui svy, `svy2': mean `uvars' if `touse'
        }
        else {
            //qui total `uvars' `wgt' if `touse', `clustopt'
            qui mean `uvars' `wgt' if `touse', `clustopt'
        }
        matrix `V' = e(V)
        local rank = e(rank)
        local df_r = e(df_r)
        if "`vce'"=="cluster" {
            local N_clust = e(N_clust)
        }
        if "`svy'"!="" {
            local svy_scalars
            foreach l in N_sub N_strata N_strata_omit singleton census N_pop ///
                         N_subpop N_psu N_poststrata stages {
                if e(`l')<. {
                    local svy_`l' = e(`l')
                    local svy_scalars `svy_scalars' `l'
                }
            }
            local svy_macros
            foreach l in prefix wtype wvar wexp singleunit strata psu fpc ///
                         poststrata postweight vce vcetype mse subpop adjust {
                local svy_`l' `"`e(`l')'"'
                local svy_macros `svy_macros' `l'
            }
            forv l=1/`svy_stages' {
                local svy_su`l' `"`e(su`l')'"'
                local svy_fpc`l' `"`e(fpc`l')'"'
                local svy_weight`l' `"`e(weight`l')'"'
                local svy_strata`l' `"`e(strata`l')'"'
                local svy_macros `svy_macros' su`l' fpc`l' weight`l' strata`l'
            }
            local svy_matrices
            foreach l in V_srs V_srssub V_srswr V_srssubwr _N_strata_single ///
                _N_strata_certain _N_strata _N_postsum _N_postsize {
                capt confirm matrix e(`l')
                if _rc==0 {
                    tempname svy_`l'
                    mat `svy_`l'' = e(`l')
                    local svy_matrices `svy_matrices' `l'
                }
            }
        }
    }

    // post results
    if "`se'"=="" {
        local coln: colfullnames `b'
        mat coln `V' = `coln'
        mat rown `V' = `coln'
    }
    else if "`weight'"=="iweight" { // add empty e(V) for svy
        tempname V
        mat `V' = `b'' * `b' * 0
    }
    if "`swap'"!="" {   // flip equations and coefficients
        mata: _robstat_swap_eq_and_coefs(`k_eq', `k_coef')
    }
    eret post `b' `V' `wgt', obs(`N') esample(`touse')
    eret local cmd "robstat"
    eret local depvar "`varlist'"
    if "`svy'"!="" eret local title "Survey: Robust Statistics"
    else           eret local title "Robust Statistics"
    eret scalar k_eq = `k_eq'
    eret scalar N_stats = `nstats'
    eret local statistics "`statslbl'"
    eret scalar N_vars = `ndepv'
    if "`over'"!="" {
        eret local total "`total'"
        eret local over_labels `"`over_labels'"'
        eret local over_namelist `"`overvals'"'
        eret local over "`over'"
    }
    eret scalar N_over = `N_over'
    eret mat _N = `_N'
    eret mat class = `class'
    eret mat aux = `aux'
    if "`se'"=="" {
        eret local vcetype "`vcetype'"
        eret local vce "`vce'"
        eret scalar rank = `rank'
        eret scalar df_r = `df_r'
        eret scalar level = `level'
        if "`vce'"=="cluster" {
            eret local clustvar "`clustvar'"
            eret scalar N_clust = `N_clust'
        }
        if "`svy'"!="" {
            foreach l of local svy_scalars {
                eret scalar `l' = `svy_`l''
            }
            foreach l of local svy_macros {
                eret local `l' `"`svy_`l''"'
            }
            foreach l of local svy_matrices {
                if substr("`l'", 1, 1)=="V" {
                    mat coln `svy_`l'' = `coln'
                    mat rown `svy_`l'' = `coln'
                }
                eret matrix `l' = `svy_`l''
            }
        }
    }
    
    // generate: rename uvars 
    if "`se'"=="" & "`generate'"!="" {
        local IFvars
        local i 0
        foreach v of local varlist {
            foreach overval in `overvals' `total' {
                foreach stat of local stats {
                    Make_IF_Name `generate2' `stat' `v' `ndepv' "`over'" ///
                        `overval' `stat' `nstats' // returns vname
                    capt confirm new variable `vname'
                    if _rc drop `vname'
                    local ++i
                    local uvar: word `i' of `uvars'
                    rename `uvar' `vname'
                    local IFvars `IFvars' `vname'
                }
            }
        }
        eret local IFvars `IFvars'
    }
    Return_clear // for some reason -return clear- does not delete r(S)
end
program Return_clear, rclass
    local x
end

program Make_IF_Name
    args vname stat v ndepv over overval stat nstats
    local stat: subinstr local stat ":" ""
    local uscore
    if `ndepv'>1 {
        local vname `vname'`v'
        local uscore _
    }
    if "`over'"!="" {
        local vname `vname'`uscore'`overval'
        local uscore _
    }
    if `nstats'>1 | "`uscore'"=="" {
        local vname `vname'`uscore'`stat'
    }
    c_local vname `vname'
end

program Parse_stats
    local stats
    local statslbl
    foreach s of local 0 {
        local ok = regexm(lower(`"`s'"'), "^([a-z]+)([0-9]*)$")
        if `ok' {
            local s1 = regexs(1)
            local s2 = regexs(2)
        }
        else {
            di as err `"`s' not allowed in statistics()"'
            exit 198
        }
        local l = strlen(`"`s1'"')
        // mean
        if "`s1'"==substr("mean", 1, max(1,`l')) & `"`s2'"'=="" {
            local stats     `stats'   mean
            local statslbl `statslbl' mean
            continue
        }
        // alpha-trimmed mean
        if "`s1'"==substr("alpha", 1, max(1,`l')) {
            if "`s2'"=="" local s2 5                // default is alpha5
            Parse_stats_confirm_num 1 49 `s2' `s'   // range is [1,49]
            local stats    `stats'    alpha:`s2'
            local statslbl `statslbl' alpha`s2'
            continue
        }
        // median
        if "`s1'"==substr("median", 1, max(3,`l')) & `"`s2'"'=="" {
            local stats     `stats'   median
            local statslbl `statslbl' median
            continue
        }
        // Hodges-Lehmann
        if "`s1'"=="hl" & `"`s2'"'=="" {
            local stats    `stats'    hl
            local statslbl `statslbl' HL
            continue
        }
        if "`s1'"=="hlnaive" & `"`s2'"'=="" {
            local stats    `stats'    hlnaive
            local statslbl `statslbl' HL(naive)
            continue
        }
        // Huber M
        if "`s1'"==substr("huber", 1, max(1,`l')) {
            if "`s2'"=="" local s2 95                // default is huber95
            Parse_stats_confirm_num 64 99 `s2' `s'   // range is [64,99]
            local stats    `stats'    huber:`s2'
            local statslbl `statslbl' Huber`s2'
            continue
        }
        // Biweight M
        if "`s1'"==substr("biweight", 1, max(2,`l')) {
            if "`s2'"=="" local s2 95                // default is biweight95
            Parse_stats_confirm_num 1 99 `s2' `s'    // range is [1,99]
            local stats    `stats'    biweight:`s2'
            local statslbl `statslbl' Biweight`s2'
            continue
        }
        // standard deviation
        if "`s1'"=="sd" & `"`s2'"'=="" {
            local stats     `stats'   sd
            local statslbl `statslbl' SD
            continue
        }
        // IQR
        if "`s1'"=="iqr" & `"`s2'"'=="" {
            local stats    `stats'    iqr
            local statslbl `statslbl' IQR
            continue
        }
        // IQRc
        if "`s1'"=="iqrc" & `"`s2'"'=="" {
            local stats    `stats'    iqrc
            local statslbl `statslbl' IQRc
            continue
        }
        // MAD
        if "`s1'"=="mad" & `"`s2'"'=="" {
            local stats    `stats'    mad
            local statslbl `statslbl' MAD
            continue
        }
        // MADN
        if "`s1'"=="madn" & `"`s2'"'=="" {
            local stats    `stats'    madn
            local statslbl `statslbl' MADN
            continue
        }
        // Qn coefficient
        if "`s1'"==substr("qn", 1, max(1,`l')) & `"`s2'"'=="" {
            local stats    `stats'    qn
            local statslbl `statslbl' Qn
            continue
        }
        if "`s1'"=="qnnaive" & `"`s2'"'=="" {
            local stats    `stats'    qnnaive
            local statslbl `statslbl' Qn(naive)
            continue
        }
        // M estimate of scale
        if "`s1'"=="s" {
            if "`s2'"=="" local s2 50               // default is s50
            Parse_stats_confirm_num 1 50 `s2' `s'   // range is [1,50]
            local stats    `stats'    s:`s2'
            local statslbl `statslbl' S`s2'
            continue
        }
        // skewness
        if "`s1'"==substr("skewness", 1, max(3,`l')) & `"`s2'"'=="" {
            local stats    `stats'    skewness
            local statslbl `statslbl' skewness
            continue
        }
        // SK(p)
        if "`s1'"=="sk" {
            if "`s2'"=="" local s2 25               // default is sk25
            Parse_stats_confirm_num 1 49 `s2' `s'   // range is [1,49]
            local stats    `stats'    sk:`s2'
            local statslbl `statslbl' SK`s2'
            continue
        }
        // medcouple
        if "`s1'"=="mc" & `"`s2'"'=="" {
            local stats    `stats'    mc
            local statslbl `statslbl' MC
            continue
        }
        if "`s1'"=="mcnaive" & `"`s2'"'=="" {
            local stats    `stats'    mcnaive
            local statslbl `statslbl' MC(naive)
            continue
        }
        // kurtosis
        if "`s1'"==substr("kurtosis", 1, max(1,`l')) & `"`s2'"'=="" {
            local stats    `stats'    kurtosis
            local statslbl `statslbl' kurtosis
            continue
        }
        // LQW(p)
        if "`s1'"=="qw" {
            if "`s2'"=="" local s2 25               // default is qw25
            Parse_stats_confirm_num 1 49 `s2' `s'   // range is [1,49]
            local stats    `stats'    qw:`s2'
            local statslbl `statslbl' QW`s2'
            continue
        }
        // LQW(p)
        if "`s1'"=="lqw" {
            if "`s2'"=="" local s2 25               // default is lqw25
            Parse_stats_confirm_num 1 49 `s2' `s'   // range is [1,49]
            local stats    `stats'    lqw:`s2'
            local statslbl `statslbl' LQW`s2'
            continue
        }
        // RQW(p)
        if "`s1'"=="rqw" {
            if "`s2'"=="" local s2 25               // default is rqw25
            Parse_stats_confirm_num 1 49 `s2' `s'   // range is [1,49]
            local stats    `stats'    rqw:`s2'
            local statslbl `statslbl' RQW`s2'
            continue
        }
        // LMC
        if "`s1'"=="lmc" & `"`s2'"'=="" {
            local stats    `stats'    lmc
            local statslbl `statslbl' LMC
            continue
        }
        if "`s1'"=="lmcnaive" & `"`s2'"'=="" {
            local stats    `stats'    lmcnaive
            local statslbl `statslbl' LMC(naive)
            continue
        }
        // RMC
        if "`s1'"=="rmc" & `"`s2'"'=="" {
            local stats    `stats'    rmc
            local statslbl `statslbl' RMC
            continue
        }
        if "`s1'"=="rmcnaive" & `"`s2'"'=="" {
            local stats    `stats'    rmcnaive
            local statslbl `statslbl' RMC(naive)
            continue
        }
        di as err `"`s' not allowed in statistics()"'
        exit 198
    }
    if "`stats'"=="" {
        local stats mean
        local statslbl mean
    }
    c_local stats `stats'
    c_local statslbl `statslbl'
end
program Parse_stats_confirm_num
    args l u n s
    capt numlist "`n'", min(1) max(1) range(>=`l' <=`u')
    if _rc {
        di as err `"`s' not allowed in statistics()"'
        exit 198
    }
end

program Estimate_mean, rclass
    syntax if [pw iw fw], v(str) [ u(str) * ]
    if "`weight'"=="pweight" local swgt [aw`exp']
    else if "`weight'"!=""   local swgt [`weight'`exp']
    su `v' `swgt' `if', meanonly
    tempname b
    scalar `b' = r(mean)
    if "`u'"!="" {
        qui replace `u' = (`v' - `b') `if'
    }
    return scalar b = `b'
    return scalar class = 1
end

program Estimate_alpha, rclass sortpreserve
    syntax anything(name=p) if [pw iw fw], v(str) [ u(str) * ]
    if "`weight'"=="pweight" local swgt  [aw`exp']
    else if "`weight'"!=""   local swgt  [`weight'`exp']
    local p = substr("`p'", 2, .) // strip leading colon
    marksample touse
    tempvar W
    if `"`exp'"'!="" qui gen double `W' `exp' if `touse'
    else             qui gen double `W' = 1 if `touse'
    sort `touse' `v' `W'
    qui by `touse': replace `W' = sum(`W') if `touse'
    qui by `touse': replace `W' = `W'*100/`W'[_N] if `touse'
    tempvar select
    qui by `touse': gen byte `select' = ///
        -1 + (`W'>`p') + (`W'[_n-1]>=(100-`p') & _n>1) if `touse'
    su `v' `swgt' if `touse' & `select'==0, meanonly
    tempname b
    scalar `b' = r(mean)
    if "`u'"!="" {
        tempname qlo qup plo pup
        scalar `qlo' = r(min)
        scalar `qup' = r(max)
        tempvar zlo zup
        qui gen byte `zlo' = (`select'==-1) if `touse'
        su `zlo' `swgt' if `touse', meanonly
        scalar `plo' = r(mean)
        qui gen byte `zup' = (`select'==1) if `touse'
        su `zup' `swgt' if `touse', meanonly
        scalar `pup' = r(mean)
        qui replace `u' = (`v'*(`select'==0) + `qlo'*(`zlo'-`plo') ///
                      + `qup'*(`zup'-`pup')) / (1-`plo'-`pup') - `b' if `touse'
    } 
    return scalar b = `b'
    return scalar class = 1
end

program Estimate_median, rclass
    syntax if [pw iw fw/], v(str) [ u(str) ///
        kernel(str) bw(str) adaptive(str) n(str) * ]
    if "`weight'"=="iweight" local pcwgt [aw = `exp']
    else if "`weight'"!=""   local pcwgt [`weight' = `exp']
    marksample touse
    _pctile `v' `pcwgt' if `touse', percentiles(50)
    tempname b
    scalar `b' = r(r1)
    if "`u'"!="" {
        if "`weight'"=="pweight" local swgt  [aw = `exp']
        else if "`weight'"!=""   local swgt  [`weight' = `exp']
        tempname d
        mata: robstat_kdens_s("`b'", "`d'")
        tempvar z
        qui generate byte `z' = (`v'<=`b') if `touse'
        summarize `z' `swgt' if `touse', meanonly
        qui replace `u' = (r(mean) - `z') / `d' if `touse'
    }
    return scalar b = `b'
    return scalar class = 1
end

program Estimate_hl, rclass
    syntax if [pw iw fw/], v(str) [ u(str) naive ///
        kernel(str) bw(str) adaptive(str) n(str) * ]
    if "`weight'"=="pweight" local swgt  [aw = `exp']
    else if "`weight'"!=""   local swgt  [`weight' = `exp']
    marksample touse
    tempname b
    mata: robstat_estimate_pairwise("hl") // sets scalar b
    if "`u'"!="" {
        tempvar v1 F1 dvar
        qui generate double `v1'   = 2*`b' - `v' if `touse'
        qui generate double `F1'   = .
        qui generate double `dvar' = .
        mata: robstat_relrank("`v1'", "`F1'")
        tempname mF1
        summarize `F1' `swgt' if `touse', meanonly
        scalar `mF1' = r(mean)
        mata: robstat_kdens_v("`v1'", "`dvar'")
        summarize `dvar' `swgt' if `touse', meanonly
        qui replace `u' = (`mF1' - `F1') / r(mean) if `touse'
    }
    return scalar b = `b'
    return scalar class = 1
end
program Estimate_hlnaive
    Estimate_hl `0' naive
end

program Estimate_huber, rclass
    syntax anything(name=p) if [pw iw fw/], v(str) [ u(str) ///
        tolerance(str) iterate(str) ///
        kernel(str) bw(str) adaptive(str) n(str) ]
    local p = substr("`p'", 2, .) // strip leading colon
    marksample touse
    tempname b k
    mata: robstat_estimate_m(`p', "huber", `tolerance', `iterate') 
        // returns result in b and k, fills in u
    return scalar b = `b'
    return scalar k = `k'
    return scalar class = 1
end

program Estimate_biweight, rclass
    syntax anything(name=p) if [pw iw fw/], v(str) [ u(str) ///
        tolerance(str) iterate(str) ///
        kernel(str) bw(str) adaptive(str) n(str) ]
    local p = substr("`p'", 2, .) // strip leading colon
    marksample touse
    tempname b k
    mata: robstat_estimate_m(`p', "biweight", `tolerance', `iterate') 
        // returns result in b and k, fills in u
    return scalar b = `b'
    return scalar k = `k'
    return scalar class = 1
end

program Estimate_sd, rclass
    syntax if [pw iw fw], v(str) [ u(str) * ]
    if "`weight'"=="pweight" local swgt  [aw`exp']
    else if "`weight'"!=""   local swgt  [`weight'`exp']
    qui su `v' `swgt' `if'
    tempname mean sd
    scalar `mean' = r(mean)
    scalar `sd' = r(sd)
    if (`sd'>=.) scalar `sd' = 0  // can happen if n=1
    if "`u'"!="" {
        if (`sd'!=0) {
            tempname c
            if "`weight'"=="iweight" scalar `c' = r(sum_w) / (r(sum_w) - 1)
            else                     scalar `c' = r(N) / (r(N) - 1)
            qui replace `u' = 1/(2*`sd') * (`c'*(`v'-`mean')^2 - `sd'^2) `if'
        }
    }
    return scalar b = `sd'
    return scalar class = 2
end

program Estimate_iqr, rclass
    syntax if [pw iw fw/], v(str) [ u(str) corr ///
        kernel(str) bw(str) adaptive(str) n(str) * ]
    if "`weight'"=="iweight" local pcwgt [aw = `exp']
    else if "`weight'"!=""   local pcwgt [`weight' = `exp']
    marksample touse
    tempname q1 q3 b d
    scalar `d' = cond("`corr'"!="", 1/(invnormal(0.75)-invnormal(0.25)), 1)
    _pctile `v' `pcwgt' if `touse', percentiles(25 75)
    scalar `q1' = r(r1)
    scalar `q3' = r(r2)
    scalar `b' = (`q3' - `q1') * `d'
    if "`u'"!="" {
        if "`weight'"=="pweight" local swgt  [aw = `exp']
        else if "`weight'"!=""   local swgt  [`weight' = `exp']
        tempvar  z1 z3
        tempname p1 p3
        qui generate byte `z1' = (`v'<`q1') if `touse'
        summarize `z1' `swgt' if `touse', meanonly
        scalar `p1' = r(mean)
        qui generate byte `z3' = (`v'<`q3') if `touse'
        summarize `z3' `swgt' if `touse', meanonly
        scalar `p3' = r(mean)
        tempname d1 d3
        mata: robstat_kdens_s(("`q1'", "`q3'"), ("`d1'", "`d3'"))
        qui replace `u' = `d' * ((`p3'-`z3')/`d3' - (`p1'-`z1')/`d1') if `touse'
    }
    return scalar b = `b'
    return scalar class = 2
end
program Estimate_iqrc
    Estimate_iqr `0' corr
end

program Estimate_mad, rclass
    syntax if [pw iw fw/], v(str) [ u(str) corr ///
        kernel(str) bw(str) adaptive(str) n(str) * ]
    if "`weight'"=="iweight" local pcwgt [aw = `exp']
    else if "`weight'"!=""   local pcwgt [`weight' = `exp']
    marksample touse
    tempname b med mad d
    scalar `d' = cond("`corr'"!="", 1/invnormal(0.75), 1)
    _pctile `v' `pcwgt' if `touse', percentiles(50)
    scalar `med' = r(r1)
    tempvar tmp
    qui generate double `tmp' = abs(`v' - `med') if `touse'
    _pctile `tmp' `pcwgt' if `touse', percentiles(50)
    scalar `mad' = r(r1)
    scalar `b' = `d' * `mad'
    if "`u'"!="" {
        if "`weight'"=="pweight" local swgt [aw = `exp']
        else if "`weight'"!=""   local swgt [`weight' = `exp']
        tempvar  z1 z2
        tempname p1 p2
        qui generate byte `z1' = (`tmp' <= (`b'/`d'))  if `touse'
        summarize `z1' `swgt' if `touse', meanonly
        scalar `p1' = r(mean)
        qui generate byte `z2' = (`v' <= `med')  if `touse'
        summarize `z2' `swgt' if `touse', meanonly
        scalar `p2' = r(mean)
        tempname q1 q3 d1 d2 d3
        scalar `q1' = `med' - `mad'
        scalar `q3' = `med' + `mad'
        mata: robstat_kdens_s(("`q1'", "`med'", "`q3'"), ///
                              ("`d1'", "`d2'", "`d3'"))
        qui replace `u' = `d' * ((`p1'-`z1')/(`d1'+`d3') + ///
            (`p2'-`z2')*((`d1'-`d3')/(`d2'*(`d1'+`d3')))) if `touse'
    }
    return scalar b = `b'
    return scalar class = 2
end
program Estimate_madn
    Estimate_mad `0' corr
end

program Estimate_qn, rclass
    syntax if [pw iw fw/], v(str) [ u(str) naive ///
        kernel(str) bw(str) adaptive(str) n(str) * ]
    if "`weight'"=="pweight" local swgt  [aw = `exp']
    else if "`weight'"!=""   local swgt  [`weight' = `exp']
    marksample touse
    tempname b d
    scalar `d' = 1/(sqrt(2) * invnormal(5/8))
    mata: robstat_estimate_pairwise("qn") // sets scalar b
    if "`u'"!="" {
        tempvar v1 v2 F1 F2 dvar
        qui generate double `v1'   = `v' + `b'/`d' if `touse'
        qui generate double `v2'   = `v' - `b'/`d' if `touse'
        qui generate double `F1'   = .
        qui generate double `F2'   = .
        qui generate double `dvar' = .
        mata: robstat_relrank(("`v1'", "`v2'"), ("`F1'", "`F2'"))
        tempname p1 p2
        summarize `F1' `swgt' if `touse', meanonly
        scalar `p1' = r(mean)
        summarize `F2' `swgt' if `touse', meanonly
        scalar `p2' = r(mean)
        mata: robstat_kdens_v("`v1'", "`dvar'")
        summarize `dvar' `swgt' if `touse', meanonly
        qui replace `u' = `d' * ((`p1'-`p2') - (`F1'-`F2')) / r(mean) if `touse'
    }
    return scalar b = `b'
    return scalar class = 2
end
program Estimate_qnnaive
    Estimate_qn `0' naive
end
//     if (n<=9) {
//         d = d * (0.399, 0.994, 0.512, 0.844, 0.611, 0.857, 0.669, 0.872)[n-1]
//     }
//     else {
//         if (mod(n,2)) d = d * n/(n + 1/4)
//         else          d = d * n/(n + 3.8)
//     }

program Estimate_s, rclass
    syntax anything(name=p) if [pw iw fw/], v(str) [ u(str) ///
        tolerance(str) iterate(str) ///
        kernel(str) bw(str) adaptive(str) n(str) ]
    local p = substr("`p'", 2, .) // strip leading colon
    marksample touse
    tempname b k
    mata: robstat_estimate_m(`p', "scale", `tolerance', `iterate') 
        // returns result in b and k, fills in u
    return scalar b = `b'
    return scalar k = `k'
    return scalar class = 2
end

program Estimate_skewness, rclass
    syntax if [pw iw fw], v(str) [ u(str) * ]
    if inlist("`weight'","pweight","iweight") local swgt  [aw`exp']
    else if "`weight'"!=""                    local swgt  [`weight'`exp']
    qui su `v' `swgt' `if', detail
    tempname b
    scalar `b' = r(skewness)
    if (`b'>=.) scalar `b' = 0  // can happen if n=1
    else if "`u'"!="" {
        tempvar z
        qui generate double `z' = (`v'-r(mean))/r(sd) `if'
        qui replace `u' = `z'^3 - 3*`z' - `b' - `b'*(3/2)*(`z'^2-1) `if'
    }
    return scalar b = `b'
    return scalar class = 3
end

program Estimate_sk, rclass
    syntax anything(name=p1) if [pw iw fw/], v(str) [ u(str) ///
        kernel(str) bw(str) adaptive(str) n(str) * ]
    if "`weight'"=="iweight" local pcwgt [aw = `exp']
    else if "`weight'"!=""   local pcwgt [`weight' = `exp']
    local p1 = substr("`p1'", 2, .) // strip leading colon
    local p3 = 100 - `p1'
    marksample touse
    _pctile `v' `pcwgt' if `touse', percentiles(`p1' 50 `p3')
    tempname q1 q2 q3 b
    scalar `q1' = r(r1)
    scalar `q2' = r(r2)
    scalar `q3' = r(r3)
    scalar `b' = (`q1' + `q3' - 2*`q2') / (`q3' - `q1')
    if (`b'>=.) scalar `b' = 0  // can happen if n=1
    else if "`u'"!="" {
        if "`weight'"=="pweight" local swgt [aw = `exp']
        else if "`weight'"!=""   local swgt [`weight' = `exp']
        forv i=1/3 {
            tempvar  z`i'
            tempname P`i'
            qui gen byte `z`i'' = (`v' <= `q`i'')  if `touse'
            summarize `z`i'' `swgt' if `touse', meanonly
            scalar `P`i'' = r(mean)
        }
        tempname d1 d2 d3
        mata: robstat_kdens_s(("`q1'", "`q2'", "`q3'"), ("`d1'", "`d2'", "`d3'"))
        qui replace `u' = 2 * ///
            ((`q3'-`q2')*((`P1'-`z1')/`d1' - (`P2'-`z2')/`d2')  ///
           - (`q2'-`q1')*((`P2'-`z2')/`d2' - (`P3'-`z3')/`d3')) ///
            / (`q3' - `q1')^2 if `touse'
    }
    return scalar b = `b'
    return scalar class = 3
end

program Estimate_mc, rclass
    syntax if [pw iw fw/], V0(str) [ u(str) naive ///
        kernel(str) bw(str) adaptive(str) n(str) lmc rmc * ]
    if "`weight'"=="pweight" local swgt  [aw = `exp']
    else if "`weight'"!=""   local swgt  [`weight' = `exp']
    if "`weight'"=="iweight" local pcwgt [aw = `exp']
    else if "`weight'"!=""   local pcwgt [`weight' = `exp']
    marksample touse
    tempname v b q med
    if "`lmc'"!="" {
        _pctile `v0' `pcwgt' if `touse', percentiles(50)
        scalar `med' = r(r1)
        local touse0 `touse'
        tempvar touse
        qui gen byte `touse' = `touse0' & (`v0'<`med')
        qui count if `touse' 
        if r(N)<1 {
            return scalar b = 0
            exit
        }
        _pctile `v0' `pcwgt' if `touse', percentiles(50)
        scalar `q'   = r(r1)
        qui generate double `v' = (`q' - `v0') if `touse'
        mata: robstat_estimate_pairwise("mc") // sets scalar b
        local touse `touse0'
    }
    else if "`rmc'"!="" {
        _pctile `v0' `pcwgt' if `touse', percentiles(50)
        scalar `med' = r(r1)
        local touse0 `touse'
        tempvar touse
        qui gen byte `touse' = `touse0' & (`v0'>`med')
        qui count if `touse' 
        if r(N)<1 {
            return scalar b = 0
            exit
        }
        _pctile `v0' `pcwgt' if `touse', percentiles(50)
        scalar `q'   = r(r1)
        qui generate double `v' = `v0' - `q' if `touse'
        mata: robstat_estimate_pairwise("mc") // sets scalar b
        local touse `touse0'
    }
    else {
        _pctile `v0' `pcwgt' if `touse', percentiles(50)
        scalar `q' = r(r1)
        qui generate double `v' = `v0' - `q' if `touse'
        mata: robstat_estimate_pairwise("mc") // sets scalar b
    }
    if "`u'"!="" {
        if (abs(`b')==1) {
            di as txt "(mc = " `b' ": cannot compute standard errors)"
            return scalar b = `b'
            exit
        }
        tempvar g1 g2 F1 F2 dg
        tempname mc Idg dq dH gmed Fmed
        if "`lmc'"!="" {
            scalar `mc' = -`b'
            local v `v0'
        }
        else if "`rmc'"!="" {
            scalar `mc' = -`b'
            scalar `q' = -`q'
            scalar `med' = -`med'
            drop `v'
            qui generate `v' = -`v0' if `touse'
        }
        else {
            scalar `mc' = `b'
            scalar `med' = .
            local v `v0'
        }
        qui generate `g1'   = (`v'*(`mc'-1) + 2*`q') / (`mc'+1) if `touse'
        qui generate `g2'   = (`v'*(`mc'+1) - 2*`q') / (`mc'-1) if `touse'
        qui generate `F1'   = .
        qui generate `F2'   = .
        mata: robstat_relrank(("`g1'", "`g2'"), ("`F1'", "`F2'"))
        qui generate `dg' = .
        mata: robstat_kdens_v("`g1'", "`dg'")
        qui replace `dg' = `dg' * (`v'>=`q' & `v'<=`med') if `touse'
        summarize `dg' `swgt' if `touse', meanonly
        scalar `Idg' = r(mean)
        mata: robstat_kdens_s("`q'", "`dq'")
        if "`lmc'`rmc'"!="" {
            qui replace `g1' = 32 * `dg' * ((`q'-`v')/(`mc'+1)^2) if `touse'
        }
        else {
            qui replace `g1' = 8 * `dg' * ((`v'-`q')/(`mc'+1)^2) if `touse'
        }
        summarize `g1' `swgt' if `touse', meanonly
        scalar `dH' = r(mean)
        if (`dH'==0) {
            //di as txt "(mc: cannot estimate standard errors)"
        }
        else if "`lmc'`rmc'"!="" {
            scalar `gmed' = (`med'*(`mc'-1) + 2*`q') / (`mc'+1)
            mata: robstat_relrank_s("`gmed'", "`Fmed'")
            qui replace `u' = 1/`dH' * (1 ///
                - 16*`F1'*((`v'>`q' & `v'<`med')) ///
                - 16*(`F2'-.25)*(`v'>`gmed' & `v'<`q') ///
                - 4*(`v'<`gmed') ///
                - 8*sign(`v'-`med')*`Fmed' ///
                + (.25-(`v'<`q'))*(4 - 32*`Idg'/(`dq'*(`mc'+1)))) if `touse'
        }
        else {
            qui replace `u' = 1/`dH' * ///
                (1 - 4*`F1'*(`v'>`q') - 4*(`F2'-.5)*(`v'<`q') ///
                + sign(`v'-`q')*(1 - 4*`Idg'/(`dq'*(`mc'+1)))) if `touse'
        }
        capt assert (`u'<.) if `touse'
        if _rc {
            di as txt "(mc: IF = .; cannot compute standard errors)"
            qui replace `u' = 0 if `touse'
        }
        else {
            // make sure that IF is centered at zero
            summarize `u' `swgt' if `touse', meanonly
            qui replace `u' = `u' - r(mean) if `touse'
        }
    }
    return scalar b = `b'
    return scalar class = 3
end
program Estimate_mcnaive
    Estimate_mc `0' naive
end

program Estimate_kurtosis, rclass
    syntax if [pw iw fw], v(str) [ u(str) * ]
    if inlist("`weight'","pweight","iweight") local swgt  [aw`exp']
    else if "`weight'"!=""                    local swgt  [`weight'`exp']
    qui su `v' `swgt' `if', detail
    tempname b
    scalar `b' = r(kurtosis)
    if (`b'>=.) scalar `b' = 0  // can happen if n=1
    else if "`u'"!="" {
        tempvar z
        qui generate double `z' = (`v'-r(mean))/r(sd) `if'
        qui replace `u' = (`z'^2 - `b')^2 - `b'*(`b'-1) - 4*r(skewness)*`z' `if'
    }
    return scalar b = `b'
    return scalar class = 4
end

program Estimate_qw, rclass
    syntax anything(name=p) if [pw iw fw/], v(str) [ u(str) ///
        kernel(str) bw(str) adaptive(str) n(str) * ]
    if "`weight'"=="iweight" local pcwgt [aw = `exp']
    else if "`weight'"!=""   local pcwgt [`weight' = `exp']
    local p = substr("`p'", 2, .) // strip leading colon
    local p1 = `p'/2
    local p2 = `p'          // or should this be 25?
    local p3 = 50 - `p'/2
    local p4 = 50 + `p'/2
    local p5 = 100 - `p'    // or should this be 75?
    local p6 = 100 - `p'/2
    marksample touse
    _pctile `v' `pcwgt' if `touse', percentiles(`p1' `p2' `p3' `p4' `p5' `p6')
    tempname q1 q2 q3 q4 q5 q6 b
    scalar `q1' = r(r1)
    scalar `q2' = r(r2)
    scalar `q3' = r(r3)
    scalar `q4' = r(r4)
    scalar `q5' = r(r5)
    scalar `q6' = r(r6)
    scalar `b' = (`q6' - `q4' + `q3' - `q1')/ (`q5' - `q2')
    if (`q1'==`q3') scalar `b' = 0
    else if "`u'"!="" {
        if "`weight'"=="pweight" local swgt [aw = `exp']
        else if "`weight'"!=""   local swgt [`weight' = `exp']
        forv i=1/6 {
            tempvar  z`i'
            tempname P`i'
            qui gen byte `z`i'' = (`v' <= `q`i'')  if `touse'
            summarize `z`i'' `swgt' if `touse', meanonly
            scalar `P`i'' = r(mean)
        }
        tempname d1 d2 d3 d4 d5 d6
        mata: robstat_kdens_s(  ///
            ("`q1'", "`q2'", "`q3'", "`q4'", "`q5'", "`q6'"), ///
            ("`d1'", "`d2'", "`d3'", "`d4'", "`d5'", "`d6'"))
        qui replace `u' = ///
            ((`q5'-`q2')*((`P6'-`z6')/`d6' - (`P4'-`z4')/`d4'  ///
                        + (`P3'-`z3')/`d3' - (`P1'-`z1')/`d1') ///
            - (`q6' - `q4' + `q3' - `q1') * ///
              ((`P5'-`z5')/`d5' - (`P2'-`z2')/`d2')) ///
            / (`q5' - `q2')^2 if `touse'
    }
    return scalar b = `b'
    return scalar class = 4
end

program Estimate_lqw, rclass
    syntax anything(name=p) if [pw iw fw/], v(str) [ u(str) ///
        kernel(str) bw(str) adaptive(str) n(str) * ]
    if "`weight'"=="iweight" local pcwgt [aw = `exp']
    else if "`weight'"!=""   local pcwgt [`weight' = `exp']
    local p = substr("`p'", 2, .) // strip leading colon
    local p1 = `p'/2
    local p2 = 25
    local p3 = 50 - `p'/2
    marksample touse
    _pctile `v' `pcwgt' if `touse', percentiles(`p1' `p2' `p3')
    tempname q1 q2 q3 b
    scalar `q1' = r(r1)
    scalar `q2' = r(r2)
    scalar `q3' = r(r3)
    scalar `b' = - (`q1' + `q3' - 2*`q2') / (`q3' - `q1')
    if (`q1'==`q3') scalar `b' = 0
    else if "`u'"!="" {
        if "`weight'"=="pweight" local swgt [aw = `exp']
        else if "`weight'"!=""   local swgt [`weight' = `exp']
        forv i=1/3 {
            tempvar  z`i'
            tempname P`i'
            qui gen byte `z`i'' = (`v' <= `q`i'')  if `touse'
            summarize `z`i'' `swgt' if `touse', meanonly
            scalar `P`i'' = r(mean)
        }
        tempname d1 d2 d3
        mata: robstat_kdens_s(("`q1'", "`q2'", "`q3'"), ("`d1'", "`d2'", "`d3'"))
        qui replace `u' = 2 * ///
            ((`q2'-`q1')*((`P2'-`z2')/`d2' - (`P3'-`z3')/`d3')  ///
           - (`q3'-`q2')*((`P1'-`z1')/`d1' - (`P2'-`z2')/`d2')) ///
            / (`q3' - `q1')^2 if `touse'
    }
    return scalar b = `b'
    return scalar class = 4
end

program Estimate_rqw, rclass
    syntax anything(name=p) if [pw iw fw/], v(str) [ u(str) ///
        kernel(str) bw(str) adaptive(str) n(str) * ]
    if "`weight'"=="iweight" local pcwgt [aw = `exp']
    else if "`weight'"!=""   local pcwgt [`weight' = `exp']
    local p = substr("`p'", 2, .) // strip leading colon
    local p1 = 50 + `p'/2
    local p2 = 75
    local p3 = 100 - `p'/2
    marksample touse
    _pctile `v' `pcwgt' if `touse', percentiles(`p1' `p2' `p3')
    tempname q1 q2 q3 b
    scalar `q1' = r(r1)
    scalar `q2' = r(r2)
    scalar `q3' = r(r3)
    scalar `b' = (`q1' + `q3' - 2*`q2') / (`q3' - `q1')
    if (`q1'==`q3') scalar `b' = 0
    else if "`u'"!="" {
        if "`weight'"=="pweight" local swgt [aw = `exp']
        else if "`weight'"!=""   local swgt [`weight' = `exp']
        forv i=1/3 {
            tempvar  z`i'
            tempname P`i'
            qui gen byte `z`i'' = (`v' <= `q`i'')  if `touse'
            summarize `z`i'' `swgt' if `touse', meanonly
            scalar `P`i'' = r(mean)
        }
        tempname d1 d2 d3
        mata: robstat_kdens_s(("`q1'", "`q2'", "`q3'"), ("`d1'", "`d2'", "`d3'"))
        qui replace `u' = 2 * ///
            ((`q3'-`q2')*((`P1'-`z1')/`d1' - (`P2'-`z2')/`d2')  ///
           - (`q2'-`q1')*((`P2'-`z2')/`d2' - (`P3'-`z3')/`d3')) ///
            / (`q3' - `q1')^2 if `touse'
    }
    return scalar b = `b'
    return scalar class = 4
end

program Estimate_lmc
    Estimate_mc `0' lmc
end
program Estimate_lmcnaive
    Estimate_mc `0' naive lmc
end

program Estimate_rmc
    Estimate_mc `0' rmc
end
program Estimate_rmcnaive
    Estimate_mc `0' naive rmc
end

version 11
mata mata set matastrict on
mata:

void robstat_cilog()
{
    real scalar      i, n
    string scalar    note
    real rowvector   b, se, crit, ll, ul, type
    real matrix      table
    string vector    cstripe, rstripe
    
    table   = st_matrix("r(table)")
    cstripe = st_matrixcolstripe("r(table)")[,2]
    rstripe = st_matrixrowstripe("r(table)")[,2]
    type    = st_matrix("e(class)")
    b = se = ll = ul = crit = J(1, cols(table), .)
    n = rows(rstripe)
    for (i=1;i<=n;i++) {
        if      (rstripe[i]=="b")    b    = table[i,]
        else if (rstripe[i]=="se")   se   = table[i,]
        else if (rstripe[i]=="ll")   ll   = table[i,]
        else if (rstripe[i]=="ul")   ul   = table[i,]
        else if (rstripe[i]=="crit") crit = table[i,]
    }
    n = rows(cstripe)
    for (i=1;i<=n;i++) {
        if (type[i]==2) { // Scale statistic
            se[i] = se[i] :/ b[i]
            b[i]  = ln(b[i])
            ll[i] = exp(b[i] - crit[i] * se[i])
            ul[i] = exp(b[i] + crit[i] * se[i])
        }
    }
    st_matrix(st_local("CI"), ll \ ul)
    note = "log-transformed confidence interval"
    if (allof(type, 2)) {
        if (length(type)>1) note = note + "s"
    }
    else note = note + "s for scale statistics"
    st_local("cilognote", note)
}

// helper program to rearrange b and V
void _robstat_swap_eq_and_coefs(real scalar keq, real scalar kcoef)
{
    real scalar    i, j, k
    real colvector p
    string matrix  mstripe
    
    // anything to do?
    if (keq==1 & (st_local("over")=="" | st_local("nstats")=="1")) return
    // permutation vector
    p = J(keq*kcoef, 1, .)
    i = 0
    for (j=1;j<=kcoef;j++) {
        for (k=1;k<=keq;k++) {
            p[++i] = j + kcoef*(k-1)
        }
    }
    st_local("k_eq", st_local("k_coef"))
    st_local("k_coef", strofreal(keq))
    // rearrange labels
    mstripe = st_matrixcolstripe(st_local("b"))[p,(2,1)]
    // rearrange b
    st_replacematrix(st_local("b"), st_matrix(st_local("b"))[1,p])
    st_matrixcolstripe(st_local("b"), mstripe)
    // rearrange V
    if (st_local("V")!="") {
        st_replacematrix(st_local("V"), st_matrix(st_local("V"))[p,p])
        st_matrixcolstripe(st_local("V"), mstripe)
        st_matrixrowstripe(st_local("V"), mstripe)
    }
}

// M-estimation
void robstat_estimate_m(
    real scalar p, 
    string scalar obj, 
    real scalar tol, 
    real scalar iter)
{
    real scalar    b, k, med, pw
    real colvector x, w, u
    transmorphic   S
    
    // data
    x = st_data(., st_local("v"), st_local("touse"))
    if (st_local("weight")!="") {
        w = st_data(., st_local("exp"), st_local("touse"))
        if (st_local("weight")!="fweight") w = w :/ quadsum(w) * rows(w) // normalize weights
    }
    else  w = 1
    // estimation
    med = mm_median(x, w)
    if (obj=="scale") {
        S = mm_mscale(x, w, p, ., med, 0, tol, iter)
        b = mm_mscale_b(S)
        k = mm_mscale_k(S)
    }
    else {
        S = mm_mloc(x, w, p, obj, med, ., 0, tol, iter)
        b = mm_mloc_b(S)
        k = mm_mloc_k(S)
    }
    st_numscalar(st_local("b"), b)
    st_numscalar(st_local("k"), k)
    // IFs
    if (st_local("u")=="") return
    pw = (st_local("weight")=="pweight")
    if (obj=="scale")
         u = _robstat_mscale_IF(x, w, pw, k, b, med, mm_mscale_delta(S))
    else u = _robstat_mloc_IF(x, w, pw, obj, k, b, mm_mloc_s(S), med)
    st_store(., st_local("u"), st_local("touse"), u)
}

real colvector _robstat_mloc_IF(
    real colvector x,
    real colvector w,
    real scalar    pw,
    string scalar  obj,
    real scalar    k,
    real scalar    b,
    real scalar    s,
    real scalar    med)
{
    real scalar    mad
    real colvector d, z, phi, psi, zmed, zmad
    
    mad = s * invnormal(0.75)
    d   = robstat_kdens(x, w, pw, (med-mad, med, med+mad)')
    z   = (x :- b) / s
    if (obj=="biweight") {
        phi = mm_biweight_phi(z, k)
        psi = mm_biweight_psi(z, k) 
    }
    else {
        phi = mm_huber_phi(z, k)
        psi = mm_huber_psi(z, k)
    }
    zmad = (abs(x :- med) :<= mad)
    zmed = (x :<= med)
    return((s*psi - (mean(phi:*z, w) / ((d[1]+d[3]) * invnormal(0.75))) *
            ((mean(zmad, w) :- zmad) + 
            ((d[1]-d[3])/d[2]) * (mean(zmed, w) :- zmed))) / mean(phi, w))
}

real colvector _robstat_mscale_IF(
    real colvector x,
    real colvector w,
    real scalar    pw,
    real scalar    k,
    real scalar    s,
    real scalar    med,
    real scalar    delta)
{
    real colvector d, z, psi, zmed
    
    d    = robstat_kdens(x, w, pw, med)
    z    = (x :- med) / s
    psi  = mm_biweight_psi(z, k)
    zmed = (x :<= med)
    return((s * (mm_biweight_rho(z, k) :- delta)
        - mean(psi, w)/d * (mean(zmed, w) :- zmed))
        / mean(psi:*z, w))
}

// Pairwise estimators
void robstat_estimate_pairwise(string scalar s)
{
    real scalar    fw, naive
    real colvector x, w
    
    fw    = (st_local("weight")=="fweight")
    naive = (st_local("naive")!="")
    x     = st_data(., st_local("v"), st_local("touse"))
    if (st_local("weight")=="") w = 1
    else w = st_data(., st_local("exp"), st_local("touse"))
    if      (s=="hl") st_numscalar(st_local("b"), mm_hl(x, w, fw, naive))
    else if (s=="qn") st_numscalar(st_local("b"), mm_qn(x, w, fw, naive))
    else if (s=="mc") st_numscalar(st_local("b"), mm_mc(x, w, fw, naive))
}

// density estimations
void robstat_kdens_v(string scalar atvar, string scalar dvar)
{   // store density estimate in variable
    real scalar    pw
    string scalar  touse, wtype
    real colvector x, w, at
    
    // data
    touse = st_local("touse")
    x  = st_data(., st_local("v"), touse)
    wtype = st_local("weight")
    if (wtype!="") {
        w = st_data(., st_local("exp"), touse)
        if (wtype!="fweight") w = w :/ quadsum(w) * rows(w) // normalize weights
    }
    else w = 1
    pw = wtype=="pweight"
    // density estimate
    at = st_data(., atvar, touse)
    st_store(., dvar, touse, robstat_kdens(x, w, pw, at))
}

void robstat_kdens_s(string rowvector in, string rowvector out)
{   // store density estimate in scalars
    real scalar    i, pw
    string scalar  touse, wtype
    real colvector x, w, at, d
    
    // data
    touse = st_local("touse")
    x  = st_data(., st_local("v"), touse)
    wtype = st_local("weight")
    if (wtype!="") {
        w = st_data(., st_local("exp"), touse)
        if (wtype!="fweight") w = w :/ quadsum(w) * rows(w) // normalize weights
    }
    else w = 1
    pw = wtype=="pweight"
    // density estimate
    at = J(cols(in), 1, .)
    for (i=1; i<=cols(in); i++) at[i] = st_numscalar(in[i])
    d = robstat_kdens(x, w, pw, at)
    for (i=1; i<=cols(out); i++) st_numscalar(out[i], d[i])
}

real colvector robstat_kdens(
    real colvector x,
    real colvector w,
    real scalar    pw,
    real colvector at)
{
    class mm_density scalar D
    
    if (mm_isconstant(x)) return(x[1]:==at)
    D.data(x, w, pw)
    D.kernel(st_local("kernel"), strtoreal(st_local("adaptive")))
    D.bw(st_local("bw"), 1, 2, 1)
    D.n(strtoreal(st_local("n")))
    return(D.d(at))
}

// relative ranks
void robstat_relrank(string rowvector in, string rowvector out)
{   
    string scalar  touse
    real colvector x, w
    
    touse = st_local("touse")
    x = st_data(., st_local("v"), touse)
    w = (st_local("weight")!="" ? st_data(., st_local("exp"), touse) : 1)
    st_store(., out, touse, 
        mm_relrank(x, w, st_data(., in, touse), "midpoints"!=""))
}

void robstat_relrank_s(string rowvector in, string rowvector out)
{   
    string scalar  touse
    real scalar    i
    real colvector x, w, at, r
    
    touse = st_local("touse")
    x = st_data(., st_local("v"), touse)
    w = (st_local("weight")!="" ? st_data(., st_local("exp"), touse) : 1)
    at = J(cols(in), 1, .)
    for (i=1; i<=cols(in); i++) at[i] = st_numscalar(in[i])
    r = mm_relrank(x, w, at, "midpoints"!="")
    for (i=1; i<=cols(out); i++) st_numscalar(out[i], r[i])
}

end

exit

