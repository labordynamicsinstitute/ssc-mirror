*! version 3.0.0  17jul2024
program pwmci
    
    version 12.1
    
    syntax anything(id = "arguments") [ , * ]
    
    confirm_options_allowed , `options'
    
    clean_anything `anything'
    
    tempname stats
    
    while (`"`anything'"' != "") {
        
        gettoken obs anything : anything , match(leftpar) quotes
        if ("`leftpar'" == "(") {
            gettoken obs rest : obs , quotes
            local anything `rest' `anything'
        }
        gettoken mean anything : anything , quotes
        gettoken sd   anything : anything , quotes
        
        confirm integer number `obs'
        confirm         number `mean'
        confirm         number `sd'
        
        if ( (`obs'<=0) | (`sd'<0) ) {
            
            if (`obs' <= 0) ///
                local what observations
            else ///
                local what standard deviation
            
            display as err "`what' must be positive"
            exit 498
            
        }
        
        matrix `stats' = nullmat(`stats'), (`mean',`sd',`obs')'
        
    }
    
    local k = colsof(`stats')
    if (`k' < 2) ///
        error 122
    
    matrix rownames `stats' = mean sd n
    
    return_stats `k' `stats'
    
    version `=_caller()' : pwmc , `options'
    
end


/*  _________________________________________________________________________
                                                                utilities  */

program confirm_options_allowed
    
    syntax                                          ///
    [ ,                                             ///
        MCOMPare(passthru)                          ///
        PROCedure(passthru) /// synonym for mcompare(); no longer documented
        noADJust     /// synonym for mcompare(noadjust)
        HC3                                         ///
        Welch                                       ///
        Level(cilevel)                              ///
        CIeffects                                   ///
        PVEffects                                   ///
        PValues     /// retained synonym for pveffects; no longer documented
        EFFects                                     ///
        CFORMAT(passthru)                           ///
        PFORMAT(passthru)                           ///
        SFORMAT(passthru)                           ///
        noTABle                                     ///
    ]
    
end


program clean_anything
    
    syntax anything
    
    local anything : subinstr local anything "[" "(" , all
    local anything : subinstr local anything "]" ")" , all
    
    local anything : subinstr local anything "(" " (" , all
    local anything : subinstr local anything ")" ") " , all
    
    c_local anything : copy local anything
    
end


program return_stats , rclass
    
    args k stats
    
    return visible scalar ks    = `k'*(`k'-1)/2
    return visible scalar k     = `k'
    return visible local  cmd     "pwmci"
    return hidden  matrix stats = `stats'
    
end


exit


/*  _________________________________________________________________________
                                                              version history

3.0.0   17jul2024   complete rewrite
                    new options -noadjust-, -hc3-, and -welch-
                    no longer call external Mata function
                    return r() results and pass to new pwmc.ado
2.0.0   07jan2014   no longer do any calculations
                    parse args and do minimal checking
                    call external Mata function
                    call -pwmc- to replay results
                    parentheses around args may be used
1.0.0   28jan2013   initial release on SCC
