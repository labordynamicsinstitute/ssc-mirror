*! version 3.2    Thursday, July 3, 2003 at 12:22       (SJ3-3: st0000)

/*
    syntax:
        mifit [, INDIV ]: <varlist>  [in <range>] [if <exp>] [, Level(#) Binomial Poisson]

    calls:  _mi_RUBIN.ado (v 2.0)
            _mi_unique.ado (v 1.0)
*/

program define mici, rclass
    version 7
    set more off
    preserve

/* This global macro is set in mi_RUBIN and is set to false if there is no variation between datasets*/
    global mi_combine3 T

/* Parsing arguments */
    cap assert "$mimps"!=""&"$mi_sf"!=""
    if _rc {
        display as error "please set up your data with -{help miset}- first"
        exit 198
    }

    gettoken left right: 0, parse(":")

    if trim("`left'")==""|trim("`left'")==","|trim("`left'")=="`0'" /*
        */ | trim("`right'")==":" | "`right'"==""{ error 198 }
    else if "`left'"==":" { local 0 `right' }
    else {
        local 0 `left'
        syntax [, * INDIV]
        if "`options'"!="" { error 198}
        gettoken colmn right: right, parse(":")
        local 0 `right'
    }

    syntax [varlist] [if] [in] [, Level(integer $S_level) Poisson /*
        */ Binomial Exposure(varname)]

    if "`binomial'"!="" | "`poisson'"!="" | "`exposure'"!="" {
        local options , level(`level') `binomial' `poisson' `exposure'
    }

/* Thinner list */

    _mi_unique `varlist'

    local varlist `r(unique)'
    local numbofy : word count `varlist'

/* Check binary */

    if "`binomial'"!="" {
        local x `"`varlist'"'
        tokenize `x'
        local myrc 0
        tempvar ysmall
        while "`1'"!="" {
            cap drop `ysmall'
            qui gen `ysmall' = `1' `if' `in'
            cap assert `ysmall'==0|`ysmall'==1|`ysmall'==.
            local myrc = `myrc' + _rc
            mac shift
        }
        if `myrc' {
            di in red "not binary or not 0-1 coded"
            exit 198
        }
    }

/* Estimate */

    tokenize `varlist'
    tempname memhold
    tempfile results combine
    postfile `memhold' dumyid tt obs est se lb ub using `results'

    local dumyid 1

    while "`1'"~="" {
        local yname`dumyid' `1'
        local returnc 0
        cap mido confirm numeric var `1'
        if _rc==7 {
            di "{err}`1' is a string variable, no CI available"
            exit _rc
        }
        if "`binomial'"=="" {
            forvalues i=1/$mimps {
                qui use $mi_sf`i', clear
                cap ci `1' `if' `in' `options'
                if _rc { exit _rc }
                qui ci `1' `if' `in' `options'
                post `memhold' (`dumyid') (`i') (r(N)) (r(mean)) /*
                    */ (r(se)) (r(lb)) (r(ub))
            }
        }
        else {
            forvalues i=1/$mimps {
                qui use $mi_sf`i', clear
                qui _mici_bin `1' `if' `in' `options'
                post `memhold' (`dumyid') (`i') (r(N)) (r(mean))/*
                    */ (r(se)) (r(lb)) (r(ub))
            }
        }
        local dumyid=`dumyid'+1
        mac shift
    }
    postclose `memhold'

/* Combine */
    qui use "`results'", clear
    qui gen str12 parm=" "
    forvalues i=1/`numbofy' {
        qui replace parm="`yname`i''" if dumyid==`i'
    }
    qui save `results', replace
    qui _mi_RUBIN  `numbofy' `results' `combine' `level'

/* Trap any potential errors and display messages.
The flag $mi_combine3 is set in _mi_RUBIN.ado  */

    if "$mi_combine3"=="F" {
        display as error "combining estimates is not possible: no variation between datasets"
        exit 498
    }

    use "`combine'", clear
    gen flag=0
    qui replace flag=1 if midof==.
    local sameobs 1
    forvalues i=1/`numbofy' {
        local sameobs`i' = 1
        local obsmax`i' = obs1 in `i'
        forvalues t=2/$mimps {
            if `obsmax`i'' < obs`t' in `i'{
                local obsmax`i' = obs`t' in `i'
                local sameobs`i' = 0
            }
        }
        local obsmin`i' = obs1 in `i'
        forvalues t=2/$mimps {
            if `obsmax`i'' > obs`t' in `i'{
                local obsmin`i' = obs`t' in `i'
                local sameobs`i' = 0
            }
        }
        if `sameobs`i'' == 0 {local sameobs 0}
        else {local overallobs`i' = obs`i'}
        local df`i' = midof in `i'
        local overallmean`i' = avest in `i'
        local overallse`i' = totalv in `i'
        local overallse`i' = sqrt(`overallse`i'')
        local overalllb`i' = milb in `i'
        local overallub`i' = miub in `i'
        local flag`i' = flag in `i'
    }

/* Display */
    display

/* Head */

    qui use $mi_sf$mimps, clear
    forvalues i=1/`numbofy' {
        local fmt : format `yname`i''
        if substr("`fmt'",-1,1)=="f" {
            local fmt="%9."+substr("`fmt'",-2,2)
        }
        else if substr("`fmt'",-2,2)=="fc" {
            local fmt="%9."+substr("`fmt'",-3,3)
        }
        else {
            local fmt "%9.0g"
            local fmt`i' `fmt'
        }
    }

    if "`binomial'"!="" {
        local poisbinexp "-- Binomial --"
    }
    else if "`poisson'"!="" {
        local poisbinexp "-- Poisson --"
    }

    if "`indiv'"=="" {
        local t0 " Variable"
        local dithis di in gr "Overall estimates" _col(58) "`poisbinexp'"
    }
    else {
        local t0 "     Data"
        local dithis
        local di
    }
    `dithis'
    `di'

    if "`indiv'"!="" {
        di in smcl in gr "Variable" _skip(5) _col(13) "{c |}" _col(58) "`poisbinexp'"
    }
    if "`indiv'"=="" & `sameobs'==0 {
        local t1 " Obs(min) Obs(max)"
        local t2 "     Mean"
        local t3 "    Std. Err."
        local t4 "   [`level'% Conf. Interval]"
    }
    else {
        local t1 "        Obs"
        local t2 "        Mean"
        local t3 "    Std. Err."
        local t4 "       [`level'% Conf. Interval]"
    }

    #delimit ;
    di in smcl in gr
    %12s "`t0'" _col(14)"{c |}`t1'`t2'`t3'`t4'"
    _n "{hline 13}{c +}{hline 63}" ;
    #delimit cr

/* Numerical results */

    qui use `combine', clear
    local marked 0
    local markedtoo 0
    if "`indiv'"=="" & `sameobs'==1{
        forvalues i=1/`numbofy'{
            local mark
            local marktoo
            if `sameobs`i''==0  {
                local mark {help mici_warn1 :*}
                local marked = `marked' + 1
            }
            if `flag`i''==1 {
                local marktoo {help mici_warn2 :**}
                local markedtoo= `markedtoo' + 1
            }
            di in smcl in gr /*
            */ %12s abbrev("`yname`i''",12)  " {c |}" /*
            */ _col(18) in ye %8.0f `overallobs`i''   /*
            */ _col(29) `fmt`i'' `overallmean`i''     /*
            */ _col(41) `fmt`i'' `overallse`i''       /*
            */ _col(57) `fmt`i'' `overalllb`i''       /*
            */ _col(69) `fmt`i'' `overallub`i'' in gr "`mark' `marktoo'"
        }
    }

    else if "`indiv'"=="" & `sameobs'==0{
        forvalues i=1/`numbofy'{
            local mark
            local marktoo
            if `sameobs`i''==0  {
                local mark {help mici_warn1 :*}
                local marked = `marked' + 1
            }
            if `flag`i''==1 {
                local marktoo {help mici_warn2 :**}
                local markedtoo= `markedtoo' + 1
            }
            di in smcl in gr /*
            */ %12s abbrev("`yname`i''",12)  " {c |}" /*
            */ _col(15) in ye %8.0f `obsmin`i''       /*
            */ _col(19) `fmt`i'' `obsmax`i''          /*
            */ _col(33) `fmt`i'' `overallmean`i''     /*
            */ _col(45) `fmt`i'' `overallse`i''       /*
            */ _col(57) `fmt`i'' `overalllb`i''       /*
            */ _col(69) `fmt`i'' `overallub`i'' in gr "`mark' `marktoo'"
        }
    }

    else {
        forvalues i=1/`numbofy' {
            local mark
            local marktoo
            if `sameobs`i''==0  {
                local mark {help mici_warn1 :*}
                local marked = `marked' + 1
            }
            if `flag`i''==1 {
                local marktoo {help mici_warn2 :**}
                local markedtoo= `markedtoo' + 1
            }
            local skipv = 13-length(trim(abbrev("`yname`i''",12)))
            di in smcl in gr "`yname`i''" _skip(`skipv')  _col(13) "{c |}"
            forvalues j=1/$mimps {
                local obs  = obs`j' in `i'
                local mean = est`j' in `i'
                local se   = se`j' in `i'
                local lb = lb`j' in `i'
                local ub = ub`j' in `i'
                di in smcl in gr /*
                */ %12s abbrev("$mi_sf`j'",12)  " {c |}" /*
                */ _col(18)  in ye  %8.0f `obs'      /*
                */ _col(29) `fmt`i'' `mean'     /*
                */ _col(41) `fmt`i'' `se'       /*
                */ _col(57) `fmt`i'' `lb'       /*
                */ _col(69) `fmt`i'' `ub'
            }
            di in smcl in gr /*
            */ %12s "     Overall {c |}"  /*
            */ _col(18) in ye %8.0f `overallobs`i''       /*
            */ _col(29) `fmt`i'' `overallmean`i''  /*
            */ _col(41) `fmt`i'' `overallse`i''  /*
            */ _col(57) `fmt`i'' `overalllb`i''  /*
            */ _col(69) `fmt`i'' `overallub`i''   "`mark' `marktoo'"
        }
    }

/* Save overall results */

    tempname M SE LB UB DOF RIV A
    tempvar v2se
    qui use "`combine'", clear
    qui gen double `v2se'=sqrt(totalv)
    local myrc 0
    cap mkmat avest, mat(`M')
    local myrc=`myrc'+ _rc
    cap mkmat `v2se',mat(`SE')
    local myrc=`myrc'+ _rc
    cap mat `LB'=`SE'
    local myrc=`myrc'+ _rc
    cap mat `UB' = `LB'
    local myrc=`myrc'+ _rc
    cap mkmat riv, mat(`RIV')
    local myrc=`myrc'+_rc
    local rnm
    forvalues i=1/`numbofy' {
        cap mat `LB'[`i',1] = `overalllb`i''
        local myrc=`myrc'+ _rc
        cap mat `UB'[`i',1] = `overallub`i''
        local myrc=`myrc'+ _rc
        local rnm `rnm' `yname`i''
    }

    mkmat midof,mat(`DOF')
    cap mat `A'=(`M',`SE',`LB',`UB',`DOF', `RIV')
    local myrc=`myrc'+ _rc
    if `myrc'==0 {
        matrix colnames `A' = Mean StdErr LowerBnd UpperBnd MI_df RIV
        matrix rownames `A' = `rnm'
        ret matrix overall `A'
    }
    ret local level = `level'
    ret local mimps = $mimps

end
