*! version 4.3.0  25sep2025
program tuples
    
    version 8
    
    syntax anything(id = "list")        ///
    [ ,                                 ///
        asis /* or */ VARlist           ///
        max(numlist max=1 integer>0)    ///
        min(numlist max=1 integer>0)    ///
        CONDitionals(string asis)       ///
        DIsplay                         ///
        lmacname(name local)            /// not documented
        seemata /// debugging, now ignored; not documented
        *       /// advanced method options
    ]
    
    // parse list (anything)
    
    if ("`asis'" == "") {
        
        if ("`varlist'" == "") ///
            local capture capture
        
        `capture' unab anything : `macval(anything)'
        
    }
    else    Options_incompatible `asis' `varlist'
    
    local n : word count `macval(anything)'
    
    
    // parse min() and max()
    
    if ("`max'" != "") ///
        local max = min(`max',`n')
    else ///
        local max `n'
    
    if ("`min'" != "") {
        
        if (`min' > `max') ///
            display as txt "note: min() reset to " as res `max'
        
        local min = min(`min',`max')
        
    }
    else    local min 1
    
    
    // parse advanced method options and set defaults
    
    Parse_advanced_method_options , `options'
    
    /*
        At this point, the following local macros must have been defined
        
            python      { "nopython" | "" }
            mata        { "nomata" | "" }
            sort        { "nosort" | "" }
            method      { "ncr" | "noncr" | "kronecker" | "cvp" | "naive" }
    */
    
    if (c(stata_version) < 16) ///
        local python nopython
    
    if ("`python'" != "nopython") {
        
        Find_python_script st_tuples_py
        
        if ("`st_tuples_py'" == "") ///
            local python nopython
        
    }
    
    if (c(stata_version) < 10) ///
        local mata nomata
    
    
    // parse conditionals()
    
    if (`"`conditionals'"' != "") {
        
        if (c(stata_version) < 10) ///
            Error_option_not_allowed conditionals()
        
        if ("`method'" == "naive") ///
            Options_incompatible conditionals() naive
            // NotReached
        
        if ("`python'" == "nopython") ///
            Options_incompatible conditionals() `mata'
        
        mata : infix_to_postfix("conditionals",`n')
        
    }
    
    
    // parse lmacname()
    
    if ("`lmacname'" != "") ///
        confirm name _n`lmacname's
    else ///
        local lmacname tuple
    
    
    // Done with parsing; select the tuples
    
    if ("`python'" != "nopython") {
        
        python script "`st_tuples_py'"  /// 
            , args(                     ///
                `min'                   ///
                `max'                   ///
                "conditionals"          ///
                "`display'"             ///
                "`sort'"                ///
                "`lmacname'"            ///
                `macval(anything)'      ///
            )
        
        exit
        
        // NotReached
        
    }
    
    if ("`mata'" != "nomata") {
        
        mata : tuples(                  ///
            &tuples_`method'(),         ///
            "anything",                 ///
            `n',                        ///
            `min',                      ///
            `max',                      ///
            "conditionals",             ///
            ("`display'"=="display"),   ///
            ("`sort'"!="nosort"),       ///
            "`lmacname'"                ///
            )
        
        exit
        
        // NotReached
        
    }
    
    
    // Below, we implement the Stata-based methods
    
    if ("`display'" == "") ///
        local continue continue
    
    local N = 2^`n'-1
    local ntuples = 0
    
    
    // faster variation of the baseline algorithm
    
    if ("`sort'" == "nosort") {
        
        forvalues i = 1/`N' {
            
            quietly inbase 2 `i'
            local indicators : display %0`n'.0f `r(base)'
            
            local one 0
            local tuple // void
            local space // void
            
            forvalues j = 1/`n' {
                
                if (substr("`indicators'",`j',1) == "1") {
                    
                    if (`++one' > `max') ///
                        continue , break
                    
                    local tuple `"`macval(tuple)'`space'`macval(`j')'"'
                    local space " "
                    
                }
                
            }
            
            if ( (`one'<`min') | (`one'>`max') ) ///
                continue
            
            c_local `lmacname'`++ntuples' `"`macval(tuple)'"'
            
            `continue'
            
            display as res "`lmacname'`ntuples': " as txt `"`macval(tuple)'"'
            
        }
        
        c_local n`lmacname's `ntuples'
        
        exit
        
        // NotReached
        
    }
    
    
    // Baseline algorithm (original implementation)
    
    forval I = `min'/`max' {
        
        forval i = 1/`N' {
            
            qui inbase 2 `i'
            local which `r(base)' 
            local nzeros = `n' - `: length local which' 
            local zeros : di _dup(`nzeros') "0" 
            local which `zeros'`which'  
            local which : subinstr local which "1" "1", all count(local n1) 
            
            if `n1' == `I' {
                
                local out   // void
                local space // void
                
                forval j = 1 / `n' {
                    
                    local char = substr("`which'",`j',1) 
                    if `char' {
                        
                        local out `"`macval(out)'`space'`macval(`j')'"'
                        local space " "
                        
                    }
                    
                }
                
                c_local `lmacname'`++ntuples' `"`macval(out)'"'
                
                `continue'
                
                display as res "`lmacname'`ntuples': " as txt `"`macval(out)'"'
                    
            }
            
        }
        
    }
    
    c_local n`lmacname's `ntuples'
    
end


program Parse_advanced_method_options
    
    syntax          ///
    [ ,             ///
        noPYthon    ///
        noMata      ///
        noSort      ///
        NONCR       ///
        ncr         ///
        kronecker   ///
        cvp         ///
        naive       ///
    ]
    
    if ( ("`noncr'"=="noncr") & ("`ncr'"=="ncr") ) ///
        Error_option_not_allowed noncr
        // NotReeached
    
    local method `ncr' `kronecker' `cvp' `naive'
    
    if ("`method'" != "") {
        
        Options_incompatible `method' `mata'
        
        if ( ("`method'"=="naive") & ("`sort'"!="nosort") ) {
            
            display as err "option nosort required"
            exit 198
            
        }
        
        if (c(stata_version) < 10) ///
            display as txt "note: option `method' ignored"
        
        local noncr // void; implied because any other method is -no[t]ncr-
        local python nopython
        
    }
    else    local method = substr("`noncr'",1,2)+"ncr"
    
    if (c(stata_version) < 16) ///
        local python nopython
    
    if (c(stata_version) < 10) ///
        local mata nomata
    
    c_local python  `python'
    c_local mata    `mata'
    c_local sort    `sort'
    c_local method  `method'
    
end


program Find_python_script
    
    args filename
    
    tempname rr
    
    _return hold `rr'
    
    capture python query
    if ( !_rc ) {
        
        capture findfile `filename'.py
        c_local `filename' "`r(fn)'"
        
    }
    
    _return restore `rr'
    
end


program Options_incompatible
    
    if ("`2'" != "") {
        
        display as err "options `1' and `2' may not be combined"
        exit 198
        
    }
    
end


program Error_option_not_allowed
    
    display as err "option `1' not allowed"
    exit 198
    
end




if (c(stata_version) < 10) ///
    exit




/*  _________________________________________________________________________
                                                                     Mata  */


version 10


if (c(stata_version) >= 14) ///
    local u u


mata :


mata set matastrict   on
mata set mataoptimize on


    /*  _____________________________________________________________________
                                                            select tuples  */


struct tuples_info
{
    // input
    
    string rowvector list
    real   scalar    n
    real   scalar    min
    real   scalar    max
    string rowvector conditionals
    real   scalar    is_display
    real   scalar    is_sort
    string scalar    lmacname
    
    // derived
    
    real scalar      ntuples
    real matrix      indicators
}


void tuples(
    
    pointer(function) scalar method,
    string            scalar st_anything,
    real              scalar n,
    real              scalar min,
    real              scalar max,
    string            scalar st_conditionals,
    real              scalar is_display,
    real              scalar is_sort,
    string            scalar lmacname
    
    )
{
    struct tuples_info scalar T
    
    
    T.list          = tokens(st_local(st_anything))
    T.n             = n
    T.min           = min
    T.max           = max
    T.conditionals  = tokens(st_local(st_conditionals))
    T.is_display    = is_display
    T.is_sort       = is_sort
    T.lmacname      = lmacname
    
    T.ntuples = 0
    
    (*method)(T)
    
    if ( cols(T.conditionals) ) 
        select_conditionals(T)
    
    if ( !T.ntuples )
        tuples_to_c_locals(T)
    
    stata(sprintf("c_local n%ss %f",T.lmacname,T.ntuples))
}


        /*  _________________________________________________________________
                                                    ncr (Algorithm AS 88)  */

void tuples_ncr(struct tuples_info scalar T)
{
    real scalar    kountdown
    real scalar    r
    real scalar    nmr
    real scalar    i
    real rowvector j
    
    
    if ( cols(T.conditionals) ) {
        
        tuples_ncr_conditionals(T)
        
        T.conditionals = J(1,0,"")
        
        return
        
    }
    
    
    T.ntuples = kountdown = rowsum(comb(T.n,(T.min..T.max)))
    
    r = T.max
    while ( kountdown ) {
        
        nmr = T.n-r
        j   = ((i=1)..r)
        
        while ( i ) {
            
            define_c_local(T,kountdown--,T.list[j])
            
            i = r
            
            while (j[i] >= nmr+i) if ( !(--i) ) break
            
            if ( !i )
                break
            
            j[i] = j[i] + 1
            
            while (i < r) j[i+1] = j[i++] + 1
            
        }
        
        (void) r--
        
    }
}


void tuples_ncr_conditionals(struct tuples_info scalar T)
{
    real scalar    r
    real scalar    comb
    real scalar    nmr
    real scalar    i
    real rowvector j
    real scalar    k
    
    
    r = T.min
    while (r <= T.max) {
        
        T.indicators = J(T.n,(comb=comb(T.n,r)),0)
        
        nmr = T.n-r
        j   = ((i=1)::r)
        
        while ( i ) {
            
            T.indicators[j,comb--] = J(r,1,1)
            
            i = r
            
            while (j[i] >= nmr+i) if ( !(--i) ) break
            
            if ( !i )
                break
            
            j[i] = j[i] + 1
            
            while (i < r) j[i+1] = j[i++] + 1
            
        }
        
        select_conditionals(T)
        
        for (k=1; k<=cols(T.indicators); k++)
            define_c_local(T,++T.ntuples,select(T.list,T.indicators[,k]'))
        
        (void) r++
    }
}


        /*  _________________________________________________________________
                                                                    noncr  */

void tuples_noncr(struct tuples_info scalar T)
{
    real scalar N
    real scalar i
    real scalar colsum
    
    
    T.indicators = J(T.n,(N=2^T.n),.)
    
    for (i=1; i<=T.n; i++)
        T.indicators[i,] = J(1, 2^(i-1), (J(1,(N=N/2),0),J(1,N,1)))
    
    if ( (T.min==1) & (T.max==T.n) )
        T.indicators = T.indicators[|.,2\ .,.|]
    else {
        
        colsum = colsum(T.indicators)
        T.indicators = select(T.indicators, (colsum:>=T.min):&(colsum:<=T.max))
        
    }
    
    if ( (T.n>2) & T.is_sort) {
        
        T.indicators = (colsum(T.indicators)\ T.indicators)'
        _sort(T.indicators,(1..cols(T.indicators)))
        T.indicators = T.indicators[|1,2\ .,.|]'
        
    }
}


        /*  _________________________________________________________________
                                                                kronecker  */
                                                                
void tuples_kronecker(struct tuples_info scalar T)
{
    real matrix base
    real matrix combin
    real scalar i
    
    
    base = combin = I(T.n)
    
    if (T.min == 1)
        T.indicators = uniqrows(base)
    
    for (i=1; i<T.min; i++)
        T.indicators = kronecker_update_combin(combin,base)
    
    for (i=T.min+1; i<=T.max; i++)
        T.indicators = (T.indicators,kronecker_update_combin(combin,base))
}


real matrix kronecker_update_combin(
    
    real matrix combin,
    real matrix base
    
    )
{
    combin = (J(1,cols(combin),1)#base) :+ (combin#J(1,cols(base),1))
    combin = uniqrows(select(combin,!colsum(combin:==2))')'
    return(combin)
}


        /*  _________________________________________________________________
                                                                      cvp  */

void tuples_cvp(struct tuples_info scalar T)
{
    transmorphic scalar    info
    real         scalar    i
    real         colvector p
    
    
    T.indicators = J(T.n,0,0)
    
    for (i=T.min; i<=T.max; i++) {
        
        info = cvpermutesetup((J(i,1,1)\ J(T.n-i,1,0)))
        while ( (p=cvpermute(info)) != J(0,1,.) )
            T.indicators = (T.indicators,p)
        
    }
}


        /*  _________________________________________________________________
                                                                    naive  */

void tuples_naive(struct tuples_info scalar T)
{
    real   scalar    N
    real   scalar    i
    string rowvector b
    real   scalar    len
    real   scalar    rowsum
    
    
    N = 2^T.n-1
    
    for (i=1; i<=N; i++) {
        
        b = inbase(2,i)
        
        if (len=T.n-strlen(b)) 
            b = ("0"*len+b)
        
        b = subinstr(subinstr(b,"1"," 1 "),"0"," 0 ")
        
        T.indicators = strtoreal(tokens(b))
        
        if ( (T.min>1) | (T.max<T.n) ) {
            
            rowsum = rowsum(T.indicators)
            if ( (rowsum<T.min) | (rowsum>T.max) ) 
                continue
            
        }
        
        define_c_local(T,++T.ntuples,select(T.list,T.indicators))
        
    }
}


        /*  _________________________________________________________________
                                                      define local macros  */

void tuples_to_c_locals(struct tuples_info scalar T)
{
    real scalar i
    
    
    T.ntuples = cols(T.indicators)
    
    for (i=1; i<=T.ntuples; i++) 
        define_c_local(T,i,select(T.list,T.indicators[,i]'))
}


void define_c_local(
    
    struct tuples_info scalar    T,
    real               scalar    i,
    string             rowvector tuple
    
    )
{
    st_local(T.lmacname,invtokens(tuple))
    
    stata(sprintf("c_local %s%f : copy local %s", T.lmacname,i,T.lmacname))
    
    if (T.is_display) 
        printf("{res}%s%f: {txt}%s\n", T.lmacname,i,st_local(T.lmacname))
}




    /*  _____________________________________________________________________
                                                           conditionals()  */


void infix_to_postfix(
    
    string scalar st_conditionals, 
    real   scalar n
    
    )
{
    /*
        Convert infix conditionals to postfix (Reverse Polish Notation)
        
        We implement a shunting-yard-like algorithm.
        
        Input:
        
            st_conditionals := <lmacname> := "conditionals"
            n               := number of items in the list
            
        Output:
        
            void
            
            We re-define local macro conditionals in the caller
            with space separated postfix notation.
        
        
        Only "[0-9]", "&", "|", "!", "(", ")", and <space> are allowed.
        
        <space> separates statements, so we convert
        
            <space> := ") & ("
            
            where
            
                the first <space> implies "("
                and the last <space> omits "& ("
        
        
        The order of precedence is then "!" before "&" before "|" 
        where "!" is right-associative and all others are left-associative.
        
        
        We validate the input and run the following checks:
        
            "[0-9]"         must be an integer in the interval [1;<n>]
                
                <n> := length of the list of elements
            
            "&" and "|"     must not be the first element in a statement
            
            "&" and "|"     must not be the last element in a statement
            
                "&&" and "||" are not allowed; this is not C++
            
            "!"             must not be the last element in a statement
            
            "(" and ")"     must be balanced
            
            <space>         is not allowed inside parentheses
    */
    
    transmorphic scalar    t
    string       rowvector queue 
    string       colvector stack
    string       scalar    tok
    string       scalar    top
    string       scalar    pre
    
    pragma unset pre
    
    
    t = tokeninit("", ("&","|","!","~","(",")"," "), J(1,0,""))
        tokenset(t,st_local(st_conditionals))
    
    queue = J(1,0,"")
    stack = J(0,1,"")
    
    while ((tok=tokenget(t)) != "") {
        
        if ( is_valid_number(tok,n) ) {
            
            queue = (queue,tok)
            
        }
        else if ( anyof(("&","|"), tok) ) {
            
            if ( anyof(("","("," "), pre) )
                Error_conditionals("statement may not start with "+tok)
            
            if ( anyof(("&","|","!"), pre) )
                Error_conditionals(pre+tok+" not allowed")
            
            while ( anyof(("!","&",tok), (top=pop(stack))) )
                queue = (queue,top)
            
            stack = (tok\ top\ stack)
            
        }
        else if ( anyof(("!","~"), tok) ) {
            
            if ( !anyof(("","&","|","!","("," "), pre) )
                Error_no_operator_or_space(pre+tok)
            
            tok = "!"
            
            stack = (tok\ stack)
            
        }
        else if (tok == "(") {
            
            stack = (tok\ stack)
            
        }
        else if (tok == ")") {
            
            if (pre == "(")
                Error_conditionals("invalid statement ()")
            
            while ((top=pop(stack)) != J(0,1,"")) {
                
                if (top == "(") 
                    break
                
                queue = (queue, top)
                
            }
            
            if (top != "(") 
                Error_unmatched("close")
            
            Confirm_no_operator(pre)
            
            if (!anyof(("&","|",")"," ",""), tokenpeek(t)))
                Error_no_operator_or_space(")"+tokenpeek(t))
            
        }
        else if (tok == " ") {
            
            if ( anyof(stack,"(") )
                Error_unmatched("open",0)
            
            Confirm_no_operator(pre)
            
            while (tokenpeek(t) == " ") 
                (void) tokenget(t)
            
            queue = (queue, stack')
            
            stack = (cols(queue) & tokenpeek(t)!="") ? (tok\ "&") : J(0,1,"")
            
        }
        else    Error_invalid_char(tok)
        
        pre = tok
        
    }
    
    if ( anyof(stack,"(") )
        Error_unmatched("open")
    
    Confirm_no_operator(pre)
    
    queue = queue, stack'
    
    st_local(st_conditionals, stritrim(invtokens(queue)))
}


real scalar is_valid_number(
    
    string scalar tok,
    real   scalar n
    
    )
{
    /* 
        Returns
        
            1 if tok is a valid numerical list element reference
            0 if tok is not a number or if tok is a missing value
        
        Exits with error if tok is an invalid numerical list element reference
    */
    
    real scalar number
    
    pragma unset number
    
    
    if ( _strtoreal(tok,number) ) 
        return(0)
    
    if (number != trunc(number))
        Error_invalid_char(".")
    
    if (number < 0)
        Error_invalid_char("-")
    
    if ( (number<1) | (number>n) ) {
        
        Error_conditionals()
        
        errprintf("%s illegal list element reference\n",tok)
        errprintf("positional arguments must be between 1 and %f\n",n)
        exit(missing(number) ? 127 : 125)
        
    }
    
    return(1)
}


transmorphic matrix pop(transmorphic matrix x)
{
    /*
        Strip from and return first row of x
    */
    
    transmorphic rowvector top
    
    
    if ( !rows(x) ) 
        return( J(0,cols(x),missingof(x)) )
    
    top = x[1,]
    x = (rows(x)>1) ? x[|2,.\.,.|] : J(0,cols(x),missingof(x))
    
    return(top)
}


void Confirm_no_operator(string scalar s)
{
    if ( anyof(("&","|","!"), s) )
        Error_conditionals("statement may not end with "+s)
}


        /*  _________________________________________________________________
                                                    conditionals() errors  */

void Error_conditionals(| string scalar errmsg)
{
    errprintf("option conditionals() invalid\n")
    
    if ( !args() )
        return
    
    errprintf("%s\n",errmsg)
    
    exit(198)
}


void Error_invalid_char(string scalar tok)
{
    Error_conditionals()
    
    errprintf("%s not allowed\n", `u'substr(tok,1,1))
    errprintf("only digits [0-9], &, |, !, (, ), and spaces are allowed\n")
    
    exit(198)
}


void Error_no_operator_or_space(string scalar tok)
{
    Error_conditionals("invalid "+tok+" -- missing logical operator or space")
}


void Error_unmatched(
    
    string scalar open_or_close,
  | real   scalar unmatched
    
    )
{
    
    Error_conditionals()
    
    errprintf("unmatched %s parenthesis\n",open_or_close)
    
    if ( !unmatched )
        errprintf("statements in parentheses may not contain spaces\n")
    
    exit(132)
}


    /*  _____________________________________________________________________
                                select tuples that satisfy conditionals()  */

void select_conditionals(struct tuples_info scalar T)
{
    /*
        Evaluate postfix (Reverse Polish Notation)
        
        Our stack is not composed of scalars, 
        such as "0", "1", ..., and "&", "|", ...
        but a matrix of stacked rowvectors;
        we have to use Mata's colon operators :&, :| ...
    */
    
    real scalar row
    real matrix stack
    real scalar i
    real scalar second_last
    real scalar last
    
    pragma unset row
    
    
    stack = J(0,cols(T.indicators),.)
    
    for (i=1; i<=cols(T.conditionals); i++) {
        
        if ( !_strtoreal(T.conditionals[i],row) ) {
            
            stack = (T.indicators[row,]\ stack)
            
        }
        else if (T.conditionals[i] == "&") {
            
            second_last = pop(stack)
            last        = pop(stack)
            
            stack = ((second_last :& last)\ stack)
            
        }
        else if (T.conditionals[i] == "|") {
            
            second_last = pop(stack)
            last        = pop(stack)
            
            stack = ((second_last :| last)\ stack)
            
        }
        else if (T.conditionals[i] == "!") {
            
            stack = (!pop(stack)\ stack)
            
        }
        
    }
    
    T.indicators = select(T.indicators,stack)
}


end


exit




*  4.2.2 daniel klein, Joseph N. Luchman, & NJC 12 Sep 2021
*  4.2.1 daniel klein, Joseph N. Luchman, & NJC 11 Sep 2021
*  4.2.0 Joseph N. Luchman, daniel klein, & NJC 9 Aug 2021
*  4.1.0 Joseph N. Luchman, daniel klein, & NJC 5 Aug 2021
*  4.0.3 Joseph N. Luchman, daniel klein, & NJC 16 May 2021
*  4.0.2 Joseph N. Luchman, daniel klein, & NJC 1 May 2021
*  4.0.1 Joseph N. Luchman, daniel klein, & NJC 16 May 2020
*  4.0.0 Joseph N. Luchman, daniel klein, & NJC 1 May 2020
*  3.4.1 Joseph N. Luchman, daniel klein, & NJC 14 January 2020
*  3.4.0 Joseph N. Luchman, daniel klein, & NJC 9 January 2020
*  3.3.1 Joseph N. Luchman, daniel klein, & NJC 20 December 2018
*  3.3.0 Joseph N. Luchman, daniel klein, & NJC 17 February 2016
*  3.2.1 Joseph N. Luchman 3 March 2015
*  3.2.0 Joseph N. Luchman 16 January 2015
*  3.1.0 Joseph N. Luchman 20 March 2014
*  3.0.1 NJC 1 July 2013
*  3.0.0 Joseph N. Luchman & NJC 22 June 2013
*  2.1.0 NJC 26 January 2011
*  2.0.0 NJC 3 December 2006
*  1.0.0 NJC 10 February 2003
*  all subsets of 1 ... k distinct selections from a list of k items