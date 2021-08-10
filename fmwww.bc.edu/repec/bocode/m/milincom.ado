*! version 2.3  Thursday, July 3, 2003 at 12:22        (SJ3-3: st0000)
/*
   milincom calculates individual lincoms and then combines them
   using Rubin's rule.

   Syntax :
           milincom [, INDIV] : expression [, Level(#) OR HR IRr RRr EForm]

   Call :
          _mi_RUBIN
*/

program define milincom, rclass
    version 7
    preserve

    global mi_combine3 T

    cap assert "$mimps"~=""&"$mi_sf"~=""
    if _rc {
        display as error "please set up your data with -{help miset}- first"
        exit 198
    }

    if "$mi_combine1"=="F" | "$mi_combine2"=="F" {
        di "{err} no variable defined due to combining not possible"
        exit 111
    }

/* Parsing args */

    * Process INDIV option if it is present.
    gettoken indiv express_optn: 0, parse(":")
    if trim("`indiv'")=="" | trim("`indiv'")=="," | trim("`indiv'")=="`0'" { error 198 }
    if "`indiv'"==":" { local indiv = ""}
    else {gettoken colon express_optn: express_optn, parse(":")}

    local 0 `indiv'
    syntax [, INDIV]

    * Assign the linear combination of coefs to `expression' and process the options.
    gettoken expression options: express_optn, parse(",")
    local 0 `options'
    syntax [, Level(integer $S_level) OR HR IRr RRr EForm]

    * Assign lincom options to `options'
    gettoken comma options: 0, parse(",")
    local options = trim("`options'")

    * Make OR the default option after -logistic-, as in -lincom-.
    if "`e(cmd)'"=="logistic" & "`options'"=="" {
        local options "or"
        local or "or"
    }

/* Execute lincom in individual datasets */

    local obslist=e(obs_mi1)
    forvalues i=2/$mimps{
        local obs`i'=e(obs_mi`i')
        local obslist `obslist' , `obs`i''
    }
    local miobs=min(`obslist')
    tempfile lncmfile combfile
    MILCM `"`expression'"' _mimodel $mimps `lncmfile' `indiv' `options'
    qui use `lncmfile', clear

/* Combine individual lincoms */

    qui _mi_RUBIN 1 `lncmfile' `combfile' `level'

/* Trap any potential errors and display messages.
The flag $mi_combine3 are set in _mi_RUBIN.ado  */

    if "$mi_combine3"=="F" {
        display as error "combining estimates is not possible: no variation between datasets"
        exit 498
    }

    qui use `combfile', clear
    tempname df mn se t p l u
    scalar `df' = midof in 1
    scalar `mn' = avest in 1
    scalar `se' = totalv in 1
    scalar `se' = sqrt(`se')
    scalar `t' = `mn'/`se'
    scalar `p' = 2* ttail(`df', abs(`t'))
    scalar `l' = milb in 1
    scalar `u' = miub in 1

/* Exponential transformations on overall combined results if eform, or, irr, rrr, hr options are specified*/
    if `"`or'"'!="" | `"`hr'"'!="" | `"`irr'"'!="" |`"`rrr'"'!="" |`"`eform'"'!="" {
        scalar `mn' = exp(`mn')
        scalar `se' = `mn'*`se'
        scalar `l' = exp(`l')
        scalar `u' = exp(`u')
    }
    if `df'>99999 {  local fmtdf %9.2e }
    else {  local fmtdf %9.2f }

/* Display final results */

    if "`optindiv'"=="individual"{
        local diovall ->
        local di
    }
    else { local di di }
    qui use _mitemp1, clear
    local z `e(depvar)'
    local fmt : format `z'
    if substr("`fmt'",-1,1)=="f" {
        local fmt="%9."+substr("`fmt'",-2,2)
    }
    else if substr("`fmt'",-2,2)=="fc" {
        local fmt="%9."+substr("`fmt'",-3,3)
    }
    else local fmt "%9.0g"

    `di'
    di in gr "`diovall' Overall estimates " _n
    di in gr "{hline 13}{c TT}{hline 64}"
    local t0 = abbrev("`z'",12)
    if `"`or'"'!="" {
        local tt " Odds Ratio"
    }
    else if `"`hr'"'!="" {
        local tt " Haz. Ratio"
    }
    else if `"`irr'"'!="" {
        local tt "        IRR"
    }
    else if `"`rrr'"'!="" {
        local tt "        RRR"
    }
    else if `"`eform'"'!="" {
        local tt "     exp(b)"
    }
    else {
        local tt "      Coef."
    }

    #delimit ;
    di in smcl in gr
    %12s "`t0'" _col(14)"{c |}`tt'  Std. Err.    t   P>|t|  [`level'% Conf. Interval]  MI.df"
        _n "{hline 13}{c +}{hline 64}" ;
    #delimit cr

    di in smcl in gr /*
   */  "         (1)"  _col(14) "{c |}"  /*
   */ _col(17)  in ye  `fmt'   `mn`i''   /*
   */ _col(27)  `fmt'  `se'     /*
   */ _col(36)    %7.2f    `t'  /*
   */ _col(42)    %7.3f    `p'  /*
   */ _col(51)  `fmt'  `l'      /*
   */ _col(61)  `fmt'  `u'      /*
   */ _col(69)  `fmtdf'   `df'
   di in gr "{hline 13}{c BT}{hline 64}"

/* Return overall results */

    ret scalar MI_estimate = `mn'
    ret scalar MI_se = `se'
    ret scalar MI_df = `df'
end

program define MILCM
    args expression model m results indiv options
/* expression -- the origional linear combination of variables
   model -- prefix of est hold name
   m -- # of multiple datasets
   results -- data file holding lincom results
   indiv -- MI option indiv or not
   options -- lincom options
*/
    tempfile result
    tempname memhold
    postfile `memhold' parm tt obs estimate se lb ub using `result'

/* Do lincom for each dataset */
    forvalues t=1/`m' {
        qui use $mi_sf`t', clear
        est unhold `model'`t'
        est hold `model'`t', copy
        _clearcmd
        cap lincom `expression'
        if _rc {
            cap noisily lincom `expression'
            exit _rc
        }
        * Run lincon for each dataset with options if INDIV is specified
        if "`indiv'" == "indiv" {
            __mydis $mi_sf `t'
            di in gr "-> applying lincom to `r(this)'.dta"
            lincom `expression',`options'
            display
        }
        * Run lincon for each dataset without options for the purpose of combining results with _mi_RUBIN
        qui lincom `expression'
        post `memhold' (1) (`t') (100) (r(estimate)) (r(se)) (1) (2)
        _restorecmd
    }
    postclose `memhold'
    qui use `result', clear
    qui gen str12 parm2=string(parm)
    qui drop parm
    rename parm2 parm
    order parm tt est se obs lb ub
    gen dumyid = 1
    qui save `results'
    erase `result'
end

program define __mydis, rclass
    args data i
    local short=abbrev("`data'`i'",12)
    return local this "`short'"
end

* These programs manipulate e(cmd) to avoid default behaviour of -lincom- after -logistic-
program define _clearcmd, eclass
    if "`e(cmd)'" == "logistic" {
        estimates local cmd = ""
        global S__flag 1
    }
    else {global S__flag 0}
end

program define _restorecmd, eclass
    if $S__flag == 1 {
        estimates local cmd = "logistic"
        macro drop S__flag
    }
end
