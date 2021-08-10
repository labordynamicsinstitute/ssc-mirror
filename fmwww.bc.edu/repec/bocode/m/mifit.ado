*! version 9.1   Thursday, July 3, 2003 at 12:22
/*
    syntax:
        mifit [, INDIV Level]: <estimation command>

    calls:  _mi_ESTIMATE.ado (v 2.0)
            _mi_RUBIN.ado (v 2.0)
            _mi_unique.ado (v 1.0)
*/

program define mifit, eclass
    version 7
    set more off
    preserve

    global mi_combine1 T
    global mi_combine2 T
    global mi_combine3 T

    capture assert "$mimps"~=""&"$mi_sf"~=""
    if _rc {
        display as error "please set up your data with -{help miset}- first"
        exit 198
    }

    forvalues i=1/$mimps { capture estimates drop _mimodel`i' }

/* Parsing arguments */
    local mi_indiv
    local mi_level
    local pcol=index("`0'",":")
    local first=substr("`0'", 1, `pcol'-1)
    if `pcol'==0 & trim("`first'")!="xi" /*
        */|`pcol'!=0 & trim("`first'")=="xi"{ error 198 }

    gettoken left right : 0, parse(":")
    if "`left'"==":" {
        local left
        local colon ":"
        local mi_indiv "overall"
    }
    else {
        gettoken colon right: right, parse(":")
    }

/* RHS of 1st colon */

    local xi
    local col
    local pcol=index("`right'",":")
    if `pcol' {
        gettoken xi rest: right, parse(":")
        gettoken col rest : rest, parse(":")
        if trim("`xi'")~="xi" |"`col'"~=":"|"`rest'"=="" { error 198 }
        else {
            local xi `xi' `col'
            local right `xi' `rest'
        }
    }
    else { local rest `"`right'"' }

/* Parsing est option, Thinner list */

    local or
    local eform
    gettoken a 0: rest, parse(",")
    qui _mi_unique "`a'"
    local a `r(unique)'
    local rest `a' `0'
    local right `xi' `rest'
    if "`0'"~=""{
        syntax [, or eform Level(integer $S_level) *]
        local est_level `level'
        mac drop _level
        if "`or'"~="" | "`eform'"~="" { local eform eform("Odds Ratio") }
    }
    else {  local est_level $S_level  }

    gettoken cmd rest: rest
/* check that estimation command is legal*/
    if "`cmd'" ~="regress" & "`cmd'"~="logit" & "`cmd'"~="probit" /*
     */& "`cmd'"~="clogit" & "`cmd'"~="cprobit" /*
     */& "`cmd'"~="logistic" & "`cmd'"~="glm" & "`cmd'"~="poisson" & "`cmd'"~="svyreg" /*
     */& "`cmd'"~="svylogit" & "`cmd'"~="svyprobit" & "`cmd'"~="svypois" & "`cmd'"~="xtgee" & "`cmd'"~="xtreg"{
        display as error "`cmd' invalid"
        exit 198
    }
    local pgistic=index("`cmd'","logistic")
    if `pgistic'>0 { local eform eform("Odds Ratio") }

/* LHS */

    if "`left'"~=""{
        if trim("`left'")=="," { error 198 }
        local 0 `left'
        syntax [, INDIV  Level(integer `est_level')]
        if "`indiv'"~="" {
            local mi_indiv `indiv'
        }
        else {  local mi_indiv "overall"  }
        local mi_level `level'
        mac drop _level
    }
    else {  local mi_level `est_level'  }
    if "`mi_indiv'"=="overall" { local qui qui  }
    else {  local qui }

/* Estimate individual model */
    tempfile miest_result combine_result
    `qui' _mi_ESTIMATE `"`right'"' `"`mi_indiv'"' `miest_result'

    if "`xi'" == "xi :" {
        global xi__Vars__To__Drop__  "`_dta[__xi__Vars__To__Drop__]'"
        global xi__Vars__Prefix__  "`_dta[__xi__Vars__Prefix__]'"
    }

/* Output e(b) and e(V) for individual datasets (e(b_1)..e(b_m) & e(V_1)..e(V_m)) */
    forvalues i=1/$mimps {
        matrix rb = r(b_`i')
        estimates matrix b_`i' rb
        matrix rV = r(V_`i')
        estimates matrix V_`i' rV
    }

/* Trap any potential errors and display messages.
The flags $mi_combine1 & 2 are set in _mi_ESTIMATE.ado.
$mi_combine1 & 3 are set in _mi_RUBIN.ado  */

    if "$mi_combine1"=="F" {
        display as error "combining estimates is not possible: check for collinearity"
        exit 498
    }

    if "$mi_combine2"=="F" {
        display as error "combining estimates is not possible: fitted model differs across datasets"
        exit 498
    }

    if "$mi_combine3"=="F" {
        display as error "combining estimates is not possible: no variation between datasets"
        exit 498
    }

    local depv=r(depv)
    local est_cmd=r(est_cmd)
/* Save individual results */

    forvalues i=1/$mimps {
        if "`r(obs`i')'"!="" {
            est scalar obs_mi`i' = `r(obs`i')'
        }

    est scalar subpop_flag = 0
        if "`r(n_sub`i')'"!="." {
            est scalar obs_mi`i' = `r(n_sub`i')'
            est scalar subpop_flag = 1
        }
    }

/* Combine */
    local numbofcoef = `r(numcoef1)'
    gen lb=0
    gen ub=0
    qui save `miest_result', replace
    _mi_RUBIN `numbofcoef' `miest_result' `combine_result' `mi_level'
/* Trap any potential errors and display messages.
The flags $mi_combine3 is set in _mi_RUBIN.ado  */

    if "$mi_combine3"=="F" {
        display as error "combining estimates is not possible: no variation between datasets"
        exit 498
    }


/* Display */
    _mi_estDisplay `combine_result' `depv' `mi_level' /*
        */`"`eform'"'  `"`xi'"' `"`est_cmd'"' `mi_indiv'

    est local mi_level=`mi_level'
    est local cmd `est_cmd'
    est local depv  `depv'
    qui use _mitemp1, clear
    restore, not
end

program define _mi_estDisplay, eclass
    args combres yname mi_level eform eksi est_cmd optindiv
    qui use "`combres'", clear
    tempname dof b total V invt
    mkmat midof, mat(`dof')
    mat `dof' = `dof''
    mkmat avest, mat(`b')
    matrix `b'=`b''
    matrix colnames `b'= $mi_mifit_nameb
    matrix rownames `b'= y1
    mkmat total, mat(`total')
    matrix `V'=diag(`total')
    matrix colnames `V' = $mi_mifit_nameVc
    matrix rownames `V' = $mi_mifit_nameVr
    mat colnames `dof' = $mi_mifit_nameb
    mat rownames `dof' = MI_dof
    local k1=colsof(`dof')
    local k2=rowsof(`V')
    cap assert `k1'==`k2'
    if _rc { exit 503 }

 /* Calculate CI limits for each coef */

    forvalues i=1/`k1' {
        tempname df`i' mn`i' se`i' t`i' p`i' invt`i' l`i' u`i'
        scalar `df`i'' =`dof'[1,`i']
        scalar `mn`i'' = el(`b',1,`i')
        scalar `se`i'' = sqrt(`V'[`i',`i'])
        scalar `t`i'' = `mn`i''/`se`i''
        scalar `p`i'' = 2* ttail(`df`i'', abs(`t`i''))
        scalar `invt`i'' = invttail(`df`i'', (1-`mi_level'/100)/2)
        scalar `l`i'' = `mn`i'' - `invt`i''*`se`i''
        scalar `u`i'' = `mn`i'' + `invt`i''*`se`i''
        if `"`eform'"'~="" {
            scalar `mn`i'' = exp(`mn`i'')
            scalar `se`i'' = `mn`i''*`se`i''
            scalar `l`i'' = exp(`l`i'')
            scalar `u`i'' = exp(`u`i'')
        }
    }
    if `"`eform'"'~="" {
        local k1 = `k1' -1
    }

/* Determine the maximum and minimum number of observations in each estimated
 dataset. This is for the purpose of the final display */

    local obsmax e(obs_mi1)           /* assigns obs maximum to the macro `obsmax' */
    forvalues i=2/$mimps {
        if `obsmax' < e(obs_mi`i'){
            local obsmax e(obs_mi`i')
        }
    }

    local obsmin e(obs_mi1)           /* assigns obs minimum to the macro `obsmin' */
    forvalues i=2/$mimps {
        if `obsmin' > e(obs_mi`i'){
            local obsmin e(obs_mi`i')
        }
    }

    if `obsmax' == `obsmin'{
        local obsequal 1              /* obsequal is a flag that is 1 if the number of observations*/
    }                                 /* is the same across imputations, and 0 otherwise. */
    else {
        local obsequal 0
    }
/* Hyperlink to a warning message (``*'') at the end of ``Overall Estimates''
if the number of observations differs across imputations*/
    local obswarn
    if `obsequal' == 0 {
        local obswarn {help mifit_warn1 :*}
    }

/* Display */
    if "`optindiv'"=="indiv"{
        local diovall ->
        local di
    }
    else { local di di }

    local xs: colnames `V'
    qui use _mitemp1, clear
    forvalues i=1/`k1' {
        local x: word `i' of `xs'
        if "`x'"!="_cons" {
            local fmt : format `x'
            if substr("`fmt'",-1,1)=="f" {
                local fmt="%7."+substr("`fmt'",-2,2)
            }
            else if substr("`fmt'",-2,2)=="fc" {
                local fmt="%7."+substr("`fmt'",-3,3)
            }
            else local fmt "%7.0g"
            local fmt`i' `fmt'
        }
        else { local fmt`i' `fmt1' }
    }

    `di'
    di
    di in gr "`diovall' Overall estimates " _n

/* display number of observations. If number of observations
is different across imputations, display max and min.*/
    if `obsequal' == 1 & e(subpop_flag)==0 {
        di as txt _col(51) "Number of obs" _col(67) "=" _col(70) as result %9.0g `obsmax'
    }
    if `obsequal' == 1 & e(subpop_flag)==1 {
        di as txt _col(39) "Subpopulation no. of obs" _col(67) "=" _col(70) as result %9.0g `obsmax'
    }
    if `obsequal' == 0 & e(subpop_flag)==0 {
        di as txt _col(45) "Number of obs (min)" _col(67) "=" _col(70) as result %9.0g `obsmin'
        di as txt _col(45) "Number of obs (max)" _col(67) "=" _col(70) as result %9.0g `obsmax'
    }
    if `obsequal' == 0 & e(subpop_flag)==1 {
        di as txt _col(33) "Subpopulation no. of obs (min)" _col(67) "=" _col(70) as result %9.0g `obsmin'
        di as txt _col(33) "Subpopulation no. of obs (max)" _col(67) "=" _col(70) as result %9.0g `obsmax'
    }

    di in gr "{hline 13}{c TT}{hline 64}"
    local t0 = abbrev("`yname'",12)
    if `"`eform'"'~="" {
        local tt " Odds Ratio"
    }
    else {
        local tt "      Coef."
    }

    #delimit ;
    di in smcl in gr
    %12s "`t0'" _col(14)"{c |}`tt'  Std. Err.    t   P>|t|  [`mi_level'% Conf. Interval]  MI.df"
    _n "{hline 13}{c +}{hline 64}" ;
    #delimit cr

    forvalues i=1/`k1' {
        local x: word `i' of `xs'
        if `df`i''>99999 {  local fmtdf %9.2e }
        else {  local fmtdf %9.2f }
        di in smcl in gr /*
            */  %12s abbrev("`x'",12)  _col(14) "{c |}" /*
            */ _col(17)  in ye  `fmt`i''   `mn`i''      /*
            */ _col(27)  `fmt`i''  `se`i'' /*
            */ _col(36)   %7.2f    `t`i''  /*
            */ _col(42)   %7.3f    `p`i''  /*
            */ _col(51)  `fmt`i''  `l`i''  /*
            */ _col(61)  `fmt`i''  `u`i''  /*
            */ _col(70)  `fmtdf'   `df`i'' /**/ "`obswarn'" /* obswarn is a hyperlink (``*'') */
    }                                                       /* to a warning message if obs    */
                                                            /* differs across datasets        */
    di in gr "{hline 13}{c BT}{hline 64}"

/* Save overall results */

        est mat MI_df `dof'
        est mat MI_b `b'
        est mat MI_V `V'


end
