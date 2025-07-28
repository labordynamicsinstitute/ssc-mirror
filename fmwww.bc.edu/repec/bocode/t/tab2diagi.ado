*! version 1.0.0  30apr2025
program tab2diagi
    
    version 11.2
    
    syntax anything [ , replace LEGEND * ] // options are not documented
    
    gettoken a anything : anything , parse(" \")
    gettoken b anything : anything , parse(" \")
    gettoken c anything : anything , parse(" \")
    gettoken d anything : anything , parse(" \")
    
    if (`"`c'"' == "\") {
        
        local c `d'
        gettoken d anything : anything
        
    }
    
    if (`"`anything'"' != "") ///
        error 198
    
    preserve
    
    clear
    
    quietly {
    	
        tabi `a' `c' \ `b' `d' , replace
        
        rename row refvar
        rename col classvar
        
        label variable refvar   "True state"
        label variable classvar "Classified"
        
        replace refvar   = (2 - refvar)
        replace classvar = (2 - classvar)
        
        label define refvar     0 "Pos. (D)" 1 "Neg. (~D)"
        label define classvar   0 "Pos. (+)" 1 "Neg. (-)"
        
        label values refvar   refvar
        label values classvar classvar
        
    }
    
    if ("`legend'" != "legend") ///
        local nolegend nolegend
    
    version `=_caller()' : ///
        tab2diag refvar classvar [fweight = pop] , `options' `nolegend'
    
    if ("`replace'" == "replace") ///
        restore , not
    
end


exit


/*  _________________________________________________________________________
                                                              Version history

1.0.0   30apr2025
