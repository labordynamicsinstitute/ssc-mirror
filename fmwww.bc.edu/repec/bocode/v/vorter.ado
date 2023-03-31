*! version 3.0.0  30mar2023
program vorter , rclass
    
    version 11.2
    
    
    /*
        Syntax is
            
            [ {+|-} ] <...>
        
        We set local macro
            
            <sign> :=  1 if + or nothing is typed
            <sign> := -1 if - is typed
    */
    
    gettoken plusminus zero : 0 , parse("+-") quotes
    
    if ( !inlist(`"`plusminus'"', "+", "-") ) local plusminus "+"
    else local 0 : copy local zero
    
    local sign = 0`plusminus'1
    
    
    /*
        Next is one of
            
            (1) <varlist> <...>
            
            (2) (<stat> [ , missing]) <...>
    */
    
    gettoken statspec zero : 0 , match(leftpar)
    
    if ("`leftpar'" == "(") {
        
        // is (2)
        
        parse_statspec stat missing `statspec'
        
        if ("`stat'" != "random") local numeric "numeric"
        
        local 0 : copy local zero
        
    }
    
    
    syntax varlist(`numeric' min = 2) [ if ] [ in ] ///
    [ ,                       ///
        NOT                   ///
        Return                /// not documented
        * options for -order- ///
    ]
    
    if (`"`options'"' != "") parse_order_options order_options , `options'
    
    if ( ("`stat'"!="random") & !c(N) ) error 2000
    else if ( ("`stat'"=="random") & (`"`if'`in'"'!="") ) ///
        display as txt "(note: {cmd:if} and {cmd:in} ignored)"
    
    if ("`stat'" == "") {
        
        capture confirm numeric variable `varlist'
        if ( _rc ) {
            capture noisily confirm string variable `varlist'
            if ( _rc ) exit 109
        }
        else local numeric "numeric"
        
        if (`"`if'`in'"' != "") {
            quietly count `if' `in'
            if (r(N) != 1) {
                display as err "too many observations"
                exit 498
            }
        }
        else local in "in 1"
        
    }
    
    tempvar touse
    mark `touse' `if' `in'
    
    mata : vorter(                   ///
        `sign',                      ///
        tokens(st_local("varlist")), ///
        "`touse'",                   ///
        ("`numeric'"=="numeric"),    ///
        "`stat'",                    ///
        ("`missing'"=="missing")     ///
        )
    
    if ("`not'`return'" == "") ///
        order `return(varlist)' `order_options'
    
end


program parse_statspec
    
    gettoken stat_name    0 : 0
    gettoken missing_name 0 : 0
    
    syntax anything(id = "stat") [ , Missing ]
    
    gettoken stat void : anything , qed(quotes)
    
    if ( `quotes' | (`"`void'"'!="") ) error 198
    
    local 0 , `stat'
    syntax       ///
    [ ,          ///
        Mean     ///
        COUnt    ///
        N        /// not documented
        MAx      ///
        MIn      ///
        SUm      ///
        SD       ///
        Variance ///
        RANDom   ///
        *        /// unknown <stat>
    ]
    
    if (`"`options'"' != "") {
        display as err `"`options' unkown {it:stat}"'
        exit 198
    }
    
    if ("`n'" == "n") local count count
    
    local stat `mean' `count' `max' `min' `sum' `sd' `variance' `random'
    
    if ("`count'`sd'`variance'`random'" != "") {
        if ("`missing'" == "missing") {
            display as err "option missing not allowed with `stat'"
            exit 198
        }
    }
    
    c_local `stat_name'    : copy loc stat
    c_local `missing_name' : copy loc missing
    
end


program parse_order_options
    
    /*
        Only called if at least one option specified
    */
    
    syntax name(local)  ///
    [ ,                 /// 
        FIRST           ///
        LAST            ///
        Before(varname) ///
        After(varname)  ///
        ALPHAbetic      /// ignored
        SEQuential      /// ignored
    ]
    
    foreach opts_ignored in alphabetic sequential {
        if ("``opts_ignored''" == "") continue
        display as txt "(note: option `opts_ignored' ignored)"
    }
    
    if ("`before'" != "") local before before(`before')
    if ("`after'"  != "") local after  after(`after')
    
    local order_options `first' `last' `before' `after'
    
    if (`: word count `order_opt'' > 1) {
        display as err "order: too many options specified"
        exit 198
    }
    
    if ("`order_options'" != "") local order_options ", `order_options'"
    
    c_local `namelist' : copy local order_options
    
end


version 11.2


mata :


mata set matastrict   on
mata set mataoptimize on


void vorter(

    real   scalar    sign,
    string rowvector varlist,
    string scalar    touse,
    real   scalar    is_numeric,
    string scalar    stat,
    real   scalar    missing 
    
    )
{
    transmorphic matrix values
    
    
    if (stat != "random") {
        
        if ( is_numeric ) values = st_data( ., varlist, touse)
        else              values = st_sdata(., varlist, touse)
        
        if ( missing(values) | !rows(values) )
            printf("{txt}(note:%smissing values encountered)\n", 
                (rows(values) ? " " : "all ")
                )
        
        if (stat != "") values_to_stat(values, stat, missing)
        
    }
    else values = runiform(1, cols(varlist))
    
    return_r(varlist, order(values', sign)', touse, stat, values)
}


void values_to_stat(
    
    real   matrix values,
    string scalar stat,
    real   scalar missing
    
    )
{
    if (stat == "mean") 
        values = (quadcolsum(values, missing) :/ colnonmissing(values))
    else if (stat == "count")
        values = colnonmissing(values)
    else if (stat == "max")
        values = colminmax(values, missing)[2,]
    else if (stat == "min")
        values = colminmax(values, missing)[1,]
    else if (stat == "sum")
        values = quadcolsum(values, missing)
    else if (stat == "sd")
        values = sqrt(diagonal(quadvariance(values))')
    else if (stat == "variance")
        values = diagonal(quadvariance(values))'
    else
        assert(0) // NotReached
}


void return_r(
    
    string       rowvector varlist,
    real         rowvector order,
    string       scalar    touse,
    string       scalar    stat,
    transmorphic rowvector values
    
    )
{
    string rowvector complete_varlist
    
    
    complete_varlist = st_varname(1..st_nvar())
    complete_varlist = select(complete_varlist, (complete_varlist:!=touse))
    
    st_rclear()
    
    st_global("r(corder)",  invtokens(complete_varlist))
    st_global("r(oorder)",  invtokens(varlist))
    st_global("r(varlist)", invtokens(varlist[order]))
    
    if (stat != "") {
        st_matrix("r("+stat+")", values[order])
        st_matrixrowstripe("r("+stat+")", ("",stat))
        st_matrixcolstripe(
            "r("+stat+")", 
            (J(cols(varlist),1,""),varlist[order]')
            )
    }
    
    (void) _stata("return add")
}


end


exit


/*
3.0.0   30mar2023   rewrite most of the code
                    make it rclass
                    -if- and -in- are allowed but ignored with -random-
                    correct typos in help file (thanks Nick Cox)
2.1.1   25jul2016   -if- and -in- no longer allowed with -random-
                    never released
2.1.0   22jul2016   fix bug with -in- qualifier
                    -if- qualifier now allowed w/o <stat>
2.0.0   24feb2016   new <stat> -random-
                    new option -not- does not change variable order
                    option -not- is a synonym for -return-
                    option -return- remains non-documented
                    parse -order- options before calling -order-
                    -order- option -alphabetic- ignored
                    -order- option -sequential- ignored
                    return complete varlist in original order
                    return stats in additional matrix
                    clear r() when called (imitate rclass)
                    no longer clear Mata
1.4.0   13aug2015   released as 1.3.1
                    add -sd- and -variance- as statistics
                    new suboption -missing- for <stat>
                    support -in #/#- with statistics
                    support -if- qualifier
                    warning message for missing values
                    completely revised code
1.3.0   13aug2015   sort on statistics (posted on Statalist)
1.2.0   22dec2012   string varlist allowed (never released)
1.1.0   18dec2012   return r(varlist) and r(oorder)
                    new option -return-
                    change check of -in- qualifier
                    version 11.2 declared (might work with 10)
                    sent to SSC
1.0.0   17dec2012   sent to Statalist (listserver)
