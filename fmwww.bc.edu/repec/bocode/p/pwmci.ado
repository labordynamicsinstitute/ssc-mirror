*! version 3.1.0  24mar2025
program pwmci
    
    version 12.1 , born(25nov2013)
    
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
            
            local what = cond(`obs'<=0,"observations","standard deviation")
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
        SEtype(passthru)                            ///
        HC3                /// synonym for setype(hc3); no longer documented
        df(passthru)                                ///
        Welch                /// synonym for df(welch); no longer documented
        legacydefault  /// for backwards compatibility; not documented
        Level(cilevel)                              ///
        CIeffects                                   ///
        PVEffects                                   ///
        PValues              /// synonym for pveffects; no longer documented
        EFFects                                     ///
        /// VARLabels                   /// not allowed
        /// VALLabels                   /// not allowed
        cformat(passthru)                           ///
        pformat(passthru)                           ///
        sformat(passthru)                           ///
        SUmmarize                                   ///
        /// zstd                        /// not allowed
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
    
    tempname grand_mean
    mata : st_numscalar(                                          ///
        "`grand_mean'",                                           ///
        mean(st_matrix("`stats'")[1,]',st_matrix("`stats'")[3,]') ///
        )
    
    return visible scalar ks         = `k'*(`k'-1)/2
    return visible scalar k          = `k'
    return visible local  cmd          "pwmci"
    return hidden  matrix stats      = `stats'
    return hidden  scalar grand_mean = `grand_mean' 
    
end


exit


/*  _________________________________________________________________________
                                                              version history

3.1.0   24mar2025   new option -legacydefault-; not documented
                    first release since 3.0.1  18jul2024
3.1.0-4 31oct2024   compute grad mean
3.1.0-3 25oct2025   must be born after 25nov2013
                    code polish
3.1.0-2 05oct2024   support options from pwmc.ado
                    may be born before 25nov2013
3.1.0-1 19sep2024   support options from pwmc.ado
3.0.1   18jul2024   must be born 25nov2013 or later
                    minor code polish
                    released on GitHub; not on SSC
3.0.0   17jul2024   complete rewrite
                    new options -noadjust-, -hc3-, and -welch-
                    no longer call external Mata function
                    return r() results and pass to new pwmc.ado
2.0.0   07jan2014   complete rewrite
                    parentheses around args may be used
                    parse arguments and do minimal checking
                    call external Mata function for all computations
                    call -pwmc- to replay results
1.0.0   28jan2013   initial release on SCC
